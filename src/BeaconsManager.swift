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

public let Beacons :BeaconsManager = BeaconsManager.shared

public class BeaconsManager : NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
	public static let shared = BeaconsManager()
	
	//MARK Private Variables
	internal var manager: CLLocationManager
	internal var peripheralManager: CBPeripheralManager?

	internal var monitoredGeoRegions: [GeoRegionRequest] = []
	internal var monitoredBeaconRegions: [BeaconRegionRequest] = []
	internal var advertisedDevices: [BeaconAdvertiseRequest] = []

	/// This identify the largest boundary distance allowed from a region’s center point.
	/// Attempting to monitor a region with a distance larger than this value causes the location manager
	/// to send a regionMonitoringFailure error when you monitor a region.
	public var maximumRegionMonitoringDistance: CLLocationDistance {
		get {
			return self.manager.maximumRegionMonitoringDistance
		}
	}
	
	// List of region requests currently being tracked using ranging.
	public var rangedRegions: [BeaconRegionRequest] {
		let trackedRegions = self.manager.rangedRegions
		return self.monitoredBeaconRegions.filter({ trackedRegions.contains($0.region) })
	}
	
	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.cleanAllMonitoredRegions()
		self.manager.delegate = self
	}
	
	/**
	Remove any monitored region
	(it will be executed automatically on login)
	*/
	public func cleanAllMonitoredRegions() {
		self.manager.monitoredRegions.forEach { self.manager.stopMonitoringForRegion($0) }
	}

	//MARK: Public Methods

	/**
	You can use the region-monitoring service to be notified when the user crosses a region-based boundary.
	
	- parameter coordinates:      the center point of the region
	- parameter radius:           the radius of the region in meters
	- parameter onStateDidChange: event fired when region in/out events are catched
	- parameter onError:          event fired in case of error. request is aborted automatically
	
	- throws: throws an exception if monitor is not supported or invalid region was specified
	
	- returns: request
	*/
	public func monitor(geographicRegion coordinates: CLLocationCoordinate2D, radius: CLLocationDistance, onStateDidChange: RegionStateDidChange, onError: RegionMonitorError) throws -> GeoRegionRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion.self) == false {
			throw LocationError.NotSupported
		}
		let request = GeoRegionRequest(coordinates: coordinates, radius: radius)
		request.onStateDidChange = onStateDidChange
		request.onError = onError
		self.add(request: request)
		return request
	}
	
	/**
	Monitor for beacon region in/out events or/and ranging events
	
	- parameter beacon:           beacon to observe
	- parameter events:           events you want to observe; you can monitor region boundary events (.RegionBoundary), beacon ranging (.Ranging) or both (.All).
	- parameter onStateDidChange: event fired when region in/out events are catched (only if event is set)
	- parameter onRangingBeacons: event fired when beacon is ranging (only if event is set)
	- parameter onError:          event fired in case of error. request is aborted automatically
	
	- throws: throws an exception if monitor is not supported or invalid region was specified
	
	- returns: request
	*/
	public func monitor(beacon beacon: Beacon, events: Event, onStateDidChange: RegionStateDidChange?, onRangingBeacons: RegionBeaconsRanging?, onError: RegionMonitorError) throws -> BeaconRegionRequest {
		let request = try self.createRegion(withBeacon: beacon, monitor: events)
		request.onStateDidChange = onStateDidChange
		request.onRangingBeacons = onRangingBeacons
		request.onError = onError
		request.start()
		return request
	}
	
	public func advertise(beaconName name: String, UUID: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?, powerRSSI: NSNumber, serviceUUIDs: [String]) -> Bool {
		let idx = self.advertisedDevices.indexOf { $0.name == name }
		if idx != nil { return false }
		
		guard let request = BeaconAdvertiseRequest(name: name, proximityUUID: UUID, major: major, minor: minor) else {
			return false
		}
		request.start()
		return true
	}
	
	//MARK: Private Methods
	
	internal func stopAdvertise(beaconName: String, error: LocationError?) -> Bool {
		guard let idx = self.advertisedDevices.indexOf({ $0.name == beaconName }) else {
			return false
		}
		let request = self.advertisedDevices[idx]
		request.rState = .Cancelled(error: error)
		self.advertisedDevices.removeAtIndex(idx)
		self.updateBeaconAdvertise()
		return false
	}
	
	private func createRegion(withBeacon beacon: Beacon, monitor: Event) throws -> BeaconRegionRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		guard let request = BeaconRegionRequest(beacon: beacon, monitor: monitor) else {
			throw LocationError.InvalidBeaconData
		}
		return request
	}
	
	internal func updateBeaconAdvertise() {
		let active = self.advertisedDevices.filter { $0.rState.isRunning }
		if active.count == 0 {
			self.peripheralManager?.stopAdvertising()
			self.peripheralManager = nil
		} else {
			if self.peripheralManager == nil {
				self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
			}
			active.forEach({
				if $0.rState.isPending == true {
					self.peripheralManager?.startAdvertising($0.dataToAdvertise())
				}
			})
		}
	}
	
	internal func add(request request: Request) -> Bool {
		if request.rState.canStart == false {
			return false
		}
		if self.monitoredGeoRegions.filter({ $0.UUID == request.UUID }).first != nil {
			return false
		}
		
		do {
			if let request = request as? GeoRegionRequest {
				self.monitoredGeoRegions.append(request)
				if try self.requestLocationServiceAuthorizationIfNeeded() == false {
					self.manager.startMonitoringForRegion(request.region)
					return true
				}
				return false
			} else if let request = request as? BeaconRegionRequest {
				self.monitoredBeaconRegions.append(request)
				if try self.requestLocationServiceAuthorizationIfNeeded() == false {
					if request.type.contains(Event.RegionBoundary) {
						self.manager.startMonitoringForRegion(request.region)
						self.manager.requestStateForRegion(request.region)
					}
					if request.type.contains(Event.Ranging) {
						self.manager.startRangingBeaconsInRegion(request.region)
					}
					return true
				}
				return false
			}
			return false
		} catch let err {
			self.remove(request: request, error: (err as? LocationError) )
			return false
		}
	}
	
	internal func remove(request request: Request?, error: LocationError? = nil) -> Bool {
		guard let request = request else { return false }
		if let request = request as? GeoRegionRequest {
			guard let idx = self.monitoredGeoRegions.indexOf({ $0.UUID == request.UUID }) else {
				return false
			}
			request.rState = .Cancelled(error: error)
			self.manager.stopMonitoringForRegion(request.region)
			self.monitoredGeoRegions.removeAtIndex(idx)
			return true
		} else if let request = request as? BeaconRegionRequest {
			guard let idx = self.monitoredBeaconRegions.indexOf({ $0.UUID == request.UUID }) else {
				return false
			}
			request.rState = .Cancelled(error: error)
			if request.type.contains(Event.RegionBoundary) {
				self.manager.stopMonitoringForRegion(request.region)
			}
			if request.type.contains(Event.Ranging) {
				self.monitoredBeaconRegions.removeAtIndex(idx)
			}
			return true
		}
		return false
	}
	
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
	
	internal func cancelAllMonitorsForRegion(error: LocationError) {
		let list: [[AnyObject]] = [self.monitoredBeaconRegions,self.monitoredGeoRegions]
		list.forEach { queue in
			queue.forEach({ request in
				self.remove(request: (request as! Request) , error: error)
			})
		}
	}
	
	internal func startPendingMonitors() {
		let list: [[AnyObject]] = [self.monitoredBeaconRegions,self.monitoredGeoRegions]
		list.forEach { queue in
			queue.forEach({ request in
				(request as! Request).start()
			})
		}
	}
	
	private func dispatchAuthorizationDidChange(newStatus: CLAuthorizationStatus) {
		func _dispatch(request: Request) {
			request.onAuthorizationDidChange?(newStatus)
		}
		
		self.monitoredBeaconRegions.forEach({ _dispatch($0) })
		self.monitoredGeoRegions.forEach({ _dispatch($0) })
	}
	
	@objc public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		switch status {
		case .Denied, .Restricted:
			let err = LocationError.AuthorizationDidChange(newStatus: status)
			self.cancelAllMonitorsForRegion(err)
			break
		case .AuthorizedAlways, .AuthorizedWhenInUse:
			self.startPendingMonitors()
			break
		default:
			break
		}
		self.dispatchAuthorizationDidChange(status)
	}
	
	@objc public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
		if peripheral.state == CBPeripheralManagerState.PoweredOn {
			self.advertisedDevices.forEach({ $0.start() })
		} else {
			let err = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Peripheral state changed to \(peripheral.state)"])
			self.advertisedDevices.forEach({ $0.rState = .Cancelled(error: LocationError.LocationManager(error: err)) })
			self.advertisedDevices.removeAll()
		}
	}
	
	//MARK: Location Manager Beacon/Geographic Regions
	
	@objc public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
		self.monitoredGeoRegions.filter { $0.region.identifier == region.identifier }.first?.onStateDidChange?(.Entered)
		self.monitoredBeaconRegions.filter {  $0.region.identifier == region.identifier }.first?.onStateDidChange?(.Entered)
	}
	
	@objc public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
		self.monitoredGeoRegions.filter {  $0.region.identifier == region.identifier }.first?.onStateDidChange?(.Exited)
		self.monitoredBeaconRegions.filter {  $0.region.identifier == region.identifier }.first?.onStateDidChange?(.Exited)
	}
	
	@objc public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
		let error = LocationError.LocationManager(error: error)
		self.remove(request: self.monitoredGeo(forRegion: region), error: error)
		self.remove(request: self.monitoredBeacon(forRegion: region), error: error)
	}
	
	//MARK: Location Manager Beacons
	
	@objc public func locationManager(manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: NSError) {
		self.monitoredBeaconRegions.forEach { $0.cancel(LocationError.LocationManager(error: error)) }
	}
	
	@objc public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
		self.monitoredBeaconRegions.filter {  $0.region.identifier == region.identifier }.first?.onRangingBeacons?(beacons)
	}
	
	//MARK: Helper Methods
	
	private func monitoredGeo(forRegion region: CLRegion?) -> Request? {
		guard let region = region else { return nil }
		let request = self.monitoredGeoRegions.filter { $0.region.identifier == region.identifier }.first
		return request
	}
	
	private func monitoredBeacon(forRegion region: CLRegion?) -> Request? {
		guard let region = region else { return nil }
		let request = self.monitoredBeaconRegions.filter { $0.region.identifier == region.identifier }.first
		return request
	}
}