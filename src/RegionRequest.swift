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
		/// Region to monitor
	internal var region: CLCircularRegion
		/// Is region currently monitored?
	internal(set) var isMonitored: Bool = false
	
		/// Identifier of the region
	public var identifier: String {
		get { return region.identifier }
	}
		/// Center coordinate to monitor
	public var center: CLLocationCoordinate2D {
		get { return region.center }
	}
		/// Radius of the area expressed in meters
	public var radius: CLLocationDistance {
		get { return region.radius }
	}
	
		/// Handler called when user did entered into the region
	internal var onRegionEntered: RegionHandlerStateDidChange?
		/// Handler called when user did exited from this region
	internal var onRegionExited: RegionHandlerStateDidChange?
		/// Handler called when region monitor did fail due to an error
	internal var onRegionDidFailToMonitor: RegionHandlerError?
	
	/**
	Create a new request to monitor a geographic region
	
	- parameter identifier: identifier of the region. If nil a new uuid is generated automatically to identify the region.
	- parameter location:   center coordinate of the region to monitor
	- parameter radius:     radius of the region to monitor, expressed in meters
	
	- returns: the request itself you can add to the main queue
	*/
	public init(identifier: String?, location: CLLocationCoordinate2D, radius: CLLocationDistance) {
		let regionID = (identifier ?? NSUUID().UUIDString)
		self.region = CLCircularRegion(center: location, radius: radius, identifier: regionID)
	}
	
	/**
	Chainable function used to change the handler the system call when user did entered into the region
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onRegionEntered(handler: RegionHandlerStateDidChange?) -> RegionRequest {
		self.onRegionEntered = handler
		return self
	}
	
	/**
	Chainable function used to change the handler the system call when user did exited from the region
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onRegionExited(handler: RegionHandlerStateDidChange?) -> RegionRequest {
		self.onRegionExited = handler
		return self
	}
	
	/**
	Chainable function used to change the handler the system call when user did fail to monitor the region.
	Region is then automatically removed from the queue.
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onRegionDidFailToMonitor(handler: RegionHandlerError?) -> RegionRequest {
		self.onRegionDidFailToMonitor = handler
		BeaconManager.shared.stopMonitorGeographicRegion(request: self)
		return self
	}
	
	/**
	Start monitor geographic region identified by this request
	
	- throws: throws error if monitor is not supported
	*/
	public func start() throws {
		try BeaconManager.shared.addMonitorForGeographicRegion(self)
	}
	
	/**
	Stop monitor geographic region identified by this request
	*/
	public func stop() {
		BeaconManager.shared.stopMonitorGeographicRegion(request: self)
	}
	
}

public func == (lhs: RegionRequest, rhs: RegionRequest) -> Bool {
	return (lhs.identifier == rhs.identifier)
}