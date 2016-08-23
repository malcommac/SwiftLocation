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

public enum RegionState {
	case Entered
	case Exited
}

public let Beacons :BeaconsManager = BeaconsManager.shared

public class BeaconsManager : NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
	public static let shared = BeaconsManager()
	
	internal var manager: CLLocationManager
	internal var peripheralManager: CBPeripheralManager?

	internal var monitoredGeoRegions: [GeoRegionRequest] = []
	internal var monitoredBeaconRegions: [BeaconRegionRequest] = []
	internal var monitoredBeaconRanging: [BeaconRegionRequest] = []
	internal var advertisedDevices: [BeaconAdvertiseRequest] = []

	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.manager.delegate = self
	}
	
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
	
	public func monitor(beaconRegion proximityUUID: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?, onStateDidChange: RegionStateDidChange, onError: RegionMonitorError) throws -> BeaconRegionRequest {
		let request = try self.createBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor)
		request.onStateDidChange = onStateDidChange
		request.onError = onError
		self.add(request: request)
		return request
	}
	
	public func monitor(beaconsRanging proximityUUID: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?, onRangingBeacons: RegionBeaconsRanging, onError: RegionMonitorError) throws -> BeaconRegionRequest {
		let request = try self.createBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor)
		request.onRangingBeacons = onRangingBeacons
		request.onError = onError
		return request
	}
	
	public func advertise(beaconName name: String, UUID: String, major: CLBeaconMajorValue?, minor: CLBeaconMajorValue?, powerRSSI: NSNumber, serviceUUIDs: [String]) -> Bool {
		let idx = self.advertisedDevices.indexOf { $0.name == name }
		if idx != nil { return false }
		
		guard let request = BeaconAdvertiseRequest(name: name, proximityUUID: UUID, major: major, minor: minor) else {
			return false
		}
		self.advertisedDevices.append(request)
		return true
	}
	
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
	
	private func createBeaconRegion(proximityUUID proximityUUID: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?) throws -> BeaconRegionRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		guard let request = BeaconRegionRequest(beaconProximityUUID: proximityUUID, major: major, minor: minor) else {
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
				}
			} else if let request = request as? BeaconRegionRequest {
				self.monitoredBeaconRegions.append(request)
				if try self.requestLocationServiceAuthorizationIfNeeded() == false {
					self.manager.startMonitoringForRegion(request.region)
				}
			}
		} catch let err {
			self.remove(request: request, error: (err as? LocationError) )
			return false
		}
		
		return false
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
			guard let idx = self.monitoredGeoRegions.indexOf({ $0.UUID == request.UUID }) else {
				return false
			}
			request.rState = .Cancelled(error: error)
			self.manager.stopMonitoringForRegion(request.region)
			self.monitoredBeaconRegions.removeAtIndex(idx)
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
		let list: [[Request]] = [self.monitoredBeaconRanging,self.monitoredBeaconRegions,self.monitoredGeoRegions]
		list.forEach { $0.filter({ $0.rState.isPending }).forEach({ self.remove(request: $0, error: error) }) }
	}
	
	internal func startPendingMonitors() {
		let list: [[Request]] = [self.monitoredBeaconRanging,self.monitoredBeaconRegions,self.monitoredGeoRegions]
		list.forEach { $0.filter({ $0.rState.isPending }).forEach({ $0.start() }) }
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
	
	@objc public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
		self.monitoredGeoRegions.filter { $0.region == region }.first?.onStateDidChange?(.Entered)
		self.monitoredBeaconRegions.filter { $0.region == region }.first?.onStateDidChange?(.Entered)
	}
	
	@objc public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
		self.monitoredGeoRegions.filter { $0.region == region }.first?.onStateDidChange?(.Exited)
		self.monitoredBeaconRegions.filter { $0.region == region }.first?.onStateDidChange?(.Exited)
	}
	
	@objc public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
		let error = LocationError.LocationManager(error: error)
		self.remove(request: self.monitoredGeoRegions.filter { $0.region == region }.first, error: error)
		self.remove(request: self.monitoredBeaconRegions.filter { $0.region == region }.first, error: error)
		self.remove(request: self.monitoredBeaconRanging.filter { $0.region == region }.first, error: error)
	}
	
	@objc public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
		self.monitoredBeaconRanging.filter { $0.region == region }.first?.onRangingBeacons?(beacons)
	}
}