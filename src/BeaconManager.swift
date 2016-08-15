//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2016 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreLocation
import CoreBluetooth

public let Beacon:BeaconManager = BeaconManager.shared

/// BeaconManager is the class you can use to monitor beacons and geographic regions both in background and in foreground
public class BeaconManager: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
		/// Shared instance
	public static let shared = BeaconManager()
		/// Location manager used to talk with the hardware
	internal var manager: CLLocationManager
		/// Bluetooth manager used to act as a beacon
	internal var peripheralManager: CBPeripheralManager?
	
		/// Monitored geographic regions
	private(set) var monitoredGeoRegions: [RegionRequest] = []
		/// Monitored beacons
	private(set) var monitoredBeacons: [BeaconRequest] = []
		/// Broadcasted beacons
	private(set) var broadcastedBeacons: [BeaconRequest] = []
	
	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.manager.delegate = self
	}
	
	//MARK: Monitor for Beacons
	
	/**
	Start monitoring a new beacon
	
	- parameter uuid:  This property contains the identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool
	- parameter major: The major property contains a value that can be used to group related sets of beacons. For example, a department store might assign the same major value for all of the beacons on the same floor.
	- parameter minor: The minor property specifies the individual beacon within a group. For example, for a group of beacons on the same floor of a department store, this value might be assigned to a beacon in a particular section.
	
	- throws: throws an exception if hardware does not provide beacon monitoring feature
	
	- returns: a new beacon request you can add to the main beacon manager's queue
	*/
	public func monitorForBeacon(proximityUUID uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMinorValue, onFound: DidRangeBeaconsHandler?, onError: RangeBeaconsDidFailHandler?) throws -> BeaconRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		let request = BeaconRequest(beaconWithUUID: uuid, major: major, minor: minor)
		try self.addMonitorForBeaconRegion(request)
		return request
	}
	
	/**
	Monitor a new beacon family
	
	- parameter uuid: This property contains the identifier that you use to identify your company’s beacons. All beacons of this family will be monitored by the system.
	
	- throws: throws an exception if hardware does not provide beacon monitoring feature
	
	- returns: a new beacon request you can add to the main beacon manager's queue
	*/
	public func monitorForBeaconFamily(proximityUUID uuid: String, onRangingBeacons: DidRangeBeaconsHandler?, onError: RangeBeaconsDidFailHandler?) throws -> BeaconRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		let request = BeaconRequest(beaconFamilyWithUUID: uuid)
		request.onRangeDidFoundBeacons = onRangingBeacons
		request.onRangeDidFail = onError
		try self.addMonitorForBeaconRegion(request)
		return request
	}
	
	/**
	Stop a currently running monitor
	
	- parameter request: request to stop
	*/
	public func stopMonitorForBeaconRegion(request: BeaconRequest) {
		request.state = .Unknown
	}
	
	//MARK: - Private Beacon Monitor
	
	internal func addMonitorForBeaconRegion(region: BeaconRequest) throws {
		do {
			if self.monitoredBeacons.indexOf(region) == nil {
				let requestShouldBeMade = try self.requestLocationServiceAuthorizationIfNeeded()
				if requestShouldBeMade == true {
					return
				}
				self.monitoredBeacons.append(region)
				self.startAllPendingBeaconRegionMonitors()
			}
		} catch let err {
			throw err
		}
	}
	
	private func startAllPendingBeaconRegionMonitors() {
		self.monitoredBeacons.filter({ $0.state == BeaconState.Unknown}  ).forEach({ region in
			self.manager.startMonitoringForRegion(region.beaconRegion!)
			self.manager.requestStateForRegion(region.beaconRegion!)
		})
	}
	
	//MARK: Monitor Geographic Region
	
	/**
	Monitor a new geographic region
	
	- parameter identifier: identifier you can assign to the region. If not specified an automatic identifier is generated for you.
	- parameter coordinate: the center point of the ragion
	- parameter radius:     the radius of the region in meters
	
	- throws: throws an exception if hardware does not provide beacon monitoring feature
	
	- returns: a new geographic request you can add to the main beacon manager's queue
	*/
	public func monitorGeographicRegion(identifier: String? = nil, centeredAt coordinate: CLLocationCoordinate2D, radius :CLLocationDistance, onEnter enHandler: RegionHandlerStateDidChange?, onExit exHandler: RegionHandlerStateDidChange?) throws -> RegionRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion.self) == false {
			throw LocationError.NotSupported
		}
		let geoRegion = RegionRequest(identifier: identifier, location: coordinate, radius: radius)
		geoRegion.onRegionEntered = enHandler
		geoRegion.onRegionExited = exHandler
		try self.addMonitorForGeographicRegion(geoRegion)
		return geoRegion
	}
	
	/**
	Stop monitoring a region request
	
	- parameter region: request to stop
	*/
	public func stopMonitorGeographicRegion(request region: RegionRequest) {
		if let idx = self.monitoredGeoRegions.indexOf(region) {
			self.manager.stopMonitoringForRegion(region.region)
			region.isMonitored = false
			self.monitoredGeoRegions.removeAtIndex(idx)
		}
	}
	
	
	//MARK: Act as a beacon transmitter
	
	/**
	Use your device to act like a beacon by advertising it's data. Advertising works only in foreground.
	
	- parameter beacon: beacon data to use
	*/
	public func advertise(beacon: BeaconRequest) {
		if self.broadcastedBeacons.indexOf(beacon) == nil {
			self.broadcastedBeacons.append(beacon)
			self.updateAdvertiserService()
		}
	}
	
	/**
	Stop advertising a beacon
	
	- parameter beacon: beacon
	*/
	public func stopAdvertise(beacon: BeaconRequest) {
		if let idx = self.broadcastedBeacons.indexOf(beacon) {
			self.broadcastedBeacons.removeAtIndex(idx)
			self.updateAdvertiserService()
		}
	}
	
	/**
	Stop advertising all currently advertised beacons
	*/
	public func cleanUpAllAdvertisers() {
		self.broadcastedBeacons.removeAll()
		self.updateAdvertiserService()
	}
	
	internal func updateAdvertiserService() {
		if self.broadcastedBeacons.count == 0 {
			self.peripheralManager?.stopAdvertising()
			self.peripheralManager = nil
		} else {
			self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
		}
	}
	
	//MARK: CBPeripheralManager Delegate
	
	@objc public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
		if peripheral.state == CBPeripheralManagerState.PoweredOn {
			self.broadcastedBeacons.forEach({ beacon in
				peripheral.startAdvertising(beacon.dataToAdvertise())
			})
		} else {
			self.cleanUpAllAdvertisers()
		}
	}
	
	//MARK: Private Methods
	
	private func requestLocationServiceAuthorizationIfNeeded() throws -> Bool {
		if CLLocationManager.locationAuthStatus == .Authorized(always: true) || CLLocationManager.locationAuthStatus == .Authorized(always: false) {
			return false
		}
		
		switch CLLocationManager.bundleLocationAuthType {
		case .None:
			throw LocationError.MissingAuthorizationInPlist
		case .Always:
			self.manager.requestAlwaysAuthorization()
		case .OnlyInUse:
			self.manager.requestWhenInUseAuthorization()
		}
		
		return true
	}
	
	private func cancelAllGeographicLocationMonitors(err: LocationError) {
		self.monitoredGeoRegions.forEach({ region in
			region.onRegionDidFailToMonitor?(err)
			region.isMonitored = false
		})
		self.monitoredGeoRegions.removeAll()
	}
	
	private func startAllPendingGeographicLocationMonitors() {
		self.monitoredGeoRegions.filter({ $0.isMonitored == false} ).forEach({ region in
			self.manager.startMonitoringForRegion(region.region)
			self.manager.requestStateForRegion(region.region)
		})
	}
	
	//MARK: CLLocationManager Delegate
	
	internal func addMonitorForGeographicRegion(region: RegionRequest) throws {
		do {
			if self.monitoredGeoRegions.indexOf(region) == nil {
				let requestShouldBeMade = try self.requestLocationServiceAuthorizationIfNeeded()
				if requestShouldBeMade == true {
					return
				}
				self.monitoredGeoRegions.append(region)
				self.startAllPendingGeographicLocationMonitors()
			}
		} catch let err {
			throw err
		}
	}
	
	@objc public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		switch status {
		case .Denied, .Restricted:
			let err = LocationError.AuthorizationDidChange(newStatus: status)
			self.cancelAllGeographicLocationMonitors(err)
			break
		case .AuthorizedAlways, .AuthorizedWhenInUse:
			self.startAllPendingGeographicLocationMonitors()
			break
		default:
			break
		}
	}
	
	public func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
		if let request = self.monitoredGeoRegions.filter({ request in request.region == region }).first {
			switch state {
			case .Inside:
				request.onRegionEntered?()
			case .Outside:
				request.onRegionExited?()
			default:
				break
			}
		}
	}
	
	public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
		if let request = self.monitoredGeoRegions.filter({ request in request.region == region }).first {
			request.onRegionEntered?()
		}
	}
	
	public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
		if let request = self.monitoredGeoRegions.filter({ request in request.region == region }).first {
			request.onRegionExited?()
		}
	}
	
	public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
		if let request = self.monitoredBeacons.filter({request in return request.beaconRegion == region}).first {
			request.onRangeDidFail?(LocationError.LocationManager(error: error))
			self.stopMonitorForBeaconRegion(request)
		}
	}
	
	public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
		if let request = self.monitoredBeacons.filter({request in return request.beaconRegion == region}).first {
			request.onRangeDidFoundBeacons?(beacons)
		}
	}
	
	public func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
		if let request = self.monitoredBeacons.filter({request in return request.beaconRegion == region}).first {
			request.onRangeDidFail?(LocationError.LocationManager(error: error))
			self.stopMonitorForBeaconRegion(request)
		}
	}
	

}