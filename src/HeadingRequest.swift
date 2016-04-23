//
//  LocationHeadingRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation

public class HeadingRequest: LocationManagerRequest {
	
	internal var UUID: String = NSUUID().UUIDString
	private var onSuccess: HeadingHandlerSuccess?
	private var onError: HeadingHandlerError?
	private(set) var lastHeading: CLHeading?
	public var isEnabled: Bool = true {
		didSet {
			LocationManager.shared.updateHeadingService()
		}
	}
	public var degreesInterval: CLLocationDegrees = 1 {
		didSet {
			LocationManager.shared.updateHeadingService()
		}
	}
	
	public init(withInterval: CLLocationDegrees = 1, onSuccess sHandler: HeadingHandlerSuccess?, onError eHandler: HeadingHandlerError?) {
		self.onSuccess = sHandler
		self.onError = eHandler
	}
	
	public func onSuccess(handler :HeadingHandlerSuccess) -> HeadingRequest {
		self.onSuccess = handler
		return self
	}
	
	public func onError(handler :HeadingHandlerError) -> HeadingRequest {
		self.onError = handler
		return self
	}
	
	public func start() {
		self.isEnabled = true
		LocationManager.shared.addHeadingRequest(self)
	}
	
	public func stop() {
		self.isEnabled = false
		LocationManager.shared.stopObservingHeading(self)
	}
	
	public func pause() {
		self.isEnabled = false
	}
	
	internal func didReceiveEventFromManager(error: NSError?, heading: CLHeading?) {
		if error != nil {
			self.onError?(LocationError.LocationManager(error: error!))
			return
		}
		
		if heading!.timestamp.timeIntervalSince1970 > lastHeading?.timestamp.timeIntervalSince1970 {
			self.lastHeading = heading
			self.onSuccess?(self.lastHeading!)
		}
	}
}