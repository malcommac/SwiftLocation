//
//  BeaconManager.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 19/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public class BeaconManager: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
	public static let main = BeaconManager()
	internal var manager: CLLocationManager
	internal var peripheralManager: CBPeripheralManager?
	
	private(set) var monitoredGeoRegions: [RegionRequest] = []
	private(set) var monitoredBeacons: [BeaconRequest] = []
	private(set) var broadcastedBeacons: [BeaconRequest] = []
	
	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.manager.delegate = self
	}
	
	//MARK: Monitor for Beacons
	
	public func monitorForBeacon(proximityUUID uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMinorValue) throws -> BeaconRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		let request = BeaconRequest(beaconWithUUID: uuid, major: major, minor: minor)
		try self.addMonitorForBeaconRegion(request)
		return request
	}
	
	public func monitorForBeaconFamily(proximityUUID uuid: String) throws -> BeaconRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) == false {
			throw LocationError.NotSupported
		}
		let request = BeaconRequest(beaconFamilyWithUUID: uuid)
		try self.addMonitorForBeaconRegion(request)
		return request
	}
	
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
	
	internal func stopMonitorForBeaconRegion(request: BeaconRequest) {
		request.state = .Unknown
	}
	
	private func startAllPendingBeaconRegionMonitors() {
		self.monitoredBeacons.filter({ $0.state == BeaconState.Unknown}  ).forEach({ region in
			self.manager.startMonitoringForRegion(region.beaconRegion!)
			self.manager.requestStateForRegion(region.beaconRegion!)
		})
	}
	
	//MARK: Monitor Geographic Region
	
	public func monitorGeographicRegion(identifier: String? = nil, centeredAt coordinate: CLLocationCoordinate2D, radius :CLLocationDistance) throws -> RegionRequest {
		if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion.self) == false {
			throw LocationError.NotSupported
		}
		let geoRegion = RegionRequest(identifier: identifier, location: coordinate, radius: radius)
		try self.addMonitorForGeographicRegion(geoRegion)
		return geoRegion
	}
	
	public func stopMonitorGeographicRegion(region: RegionRequest) {
		if let idx = self.monitoredGeoRegions.indexOf(region) {
			self.manager.stopMonitoringForRegion(region.region)
			region.isMonitored = false
			self.monitoredGeoRegions.removeAtIndex(idx)
		}
	}
	
	
	//MARK: Act as a beacon transmitter
	
	public func advertise(beacon: BeaconRequest) {
		if self.broadcastedBeacons.indexOf(beacon) == nil {
			self.broadcastedBeacons.append(beacon)
			self.updateAdvertiserService()
		}
	}
	
	public func stopAdvertise(beacon: BeaconRequest) {
		if let idx = self.broadcastedBeacons.indexOf(beacon) {
			self.broadcastedBeacons.removeAtIndex(idx)
			self.updateAdvertiserService()
		}
	}
	
	internal func cleanUpAllAdvertisers() {
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