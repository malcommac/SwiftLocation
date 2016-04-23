//
//  RegionRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 20/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public class RegionRequest : Equatable {
	internal var region: CLCircularRegion
	internal(set) var isMonitored: Bool = false
	public var identifier: String {
		get { return region.identifier }
	}
	public var center: CLLocationCoordinate2D {
		get { return region.center }
	}
	public var radius: CLLocationDistance {
		get { return region.radius }
	}
	public var onRegionEntered: RegionHandlerStateDidChange?
	public var onRegionExited: RegionHandlerStateDidChange?
	public var onRegionDidFailToMonitor: RegionHandlerError?
	
	public init(identifier: String?, location: CLLocationCoordinate2D, radius: CLLocationDistance) {
		let regionID = (identifier ?? NSUUID().UUIDString)
		self.region = CLCircularRegion(center: location, radius: radius, identifier: regionID)
	}
	
	public func onRegionEntered(handler: RegionHandlerStateDidChange?) -> RegionRequest {
		self.onRegionEntered = handler
		return self
	}
	
	public func onRegionExited(handler: RegionHandlerStateDidChange?) -> RegionRequest {
		self.onRegionExited = handler
		return self
	}
	
	public func onRegionDidFailToMonitor(handler: RegionHandlerError?) -> RegionRequest {
		self.onRegionDidFailToMonitor = handler
		return self
	}
	
	public func start() throws {
		try BeaconManager.main.addMonitorForGeographicRegion(self)
	}
	
	public func stop() {
		BeaconManager.main.stopMonitorGeographicRegion(self)
	}
	
}

public func == (lhs: RegionRequest, rhs: RegionRequest) -> Bool {
	return (lhs.identifier == rhs.identifier)
}