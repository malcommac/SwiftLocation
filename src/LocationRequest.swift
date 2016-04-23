//
//  SwiftLocationHandler.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class LocationRequest: LocationManagerRequest {
	private var onErrorHandler: LocationHandlerError?
	private var onSuccessHandler: LocationHandlerSuccess?
	private var timeoutTimer: NSTimer?
	
	internal var isEnabled: Bool = true {
		didSet {
			let shouldEnable = isEnabled
			self.setTimeoutTimer(shouldEnable)
		}
	}
	
	public var activityType: CLActivityType = .Other {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	
	public var timeout: NSTimeInterval = 0
	
	private(set) var lastLocation: CLLocation?
	
	public var frequency: UpdateFrequency = .Continuous {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	public var accuracy: Accuracy = .City {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	internal var UUID: String = NSUUID().UUIDString
	
	public init(withAccuracy accuracy: Accuracy, andFrequency frequency: UpdateFrequency) {
		self.accuracy = accuracy
		self.frequency = frequency
	}
	
	public func onError(err: LocationHandlerError) -> LocationRequest {
		self.onErrorHandler = err
		return self
	}
	
	public func onSuccess(succ: LocationHandlerSuccess) -> LocationRequest {
		self.onSuccessHandler = succ
		return self
	}
	
	public func stop() {
		self.isEnabled = false
		LocationManager.shared.stopObservingLocation(self)
	}
	
	public func pause() -> LocationRequest {
		self.isEnabled = false
		LocationManager.shared.updateLocationUpdateService()
		return self
	}
	
	public func start() -> LocationRequest {
		self.isEnabled = true
		LocationManager.shared.addLocationRequest(self)
		return self
	}
	
	internal func setTimeoutTimer(start: Bool) {
		if let _ = self.timeoutTimer {
			self.timeoutTimer!.invalidate()
			self.timeoutTimer = nil
		}
		if start == true {
			self.timeoutTimer = NSTimer(timeInterval: self.timeout, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
		}
	}
	
	@objc func timeoutTimerFired() {
		if self.onErrorHandler != nil {
			self.onErrorHandler!(LocationError.RequestTimeout)
		}
		self.stop()
	}
	
	internal func didReceiveEventFromLocationManager(error error: LocationError?, location: CLLocation?) -> Bool {
		if let error = error {
			self.onErrorHandler?(error)
			self.stop()
			return true
		}
		
		if let location = location {
			if self.isValidLocation(location) == false {
				return false
			}
			self.lastLocation = location
			self.onSuccessHandler?(self.lastLocation!)
			if self.frequency == .OneShot {
				self.stop()
			}
			return true
		}
		
		return false
	}
	
	internal func isValidLocation(loc: CLLocation) -> Bool {
		if self.accuracy.isLocationValidForAccuracy(loc) == false {
			return false
		}
		
		if let lastLocation = self.lastLocation {
			if case .ByDistanceIntervals(let meters) = self.frequency {
				let distanceSinceLastReport = lastLocation.distanceFromLocation(loc)
				if distanceSinceLastReport < meters {
					return false
				}
			}
		}
		
		let afterLastLocation = (self.lastLocation == nil ? true : loc.timestamp.timeIntervalSince1970 >= self.lastLocation!.timestamp.timeIntervalSince1970)
		if afterLastLocation == false {
			return false
		}
		
		return true
	}
	
	public func reverseLocation(onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) throws  {
		guard let loc = self.lastLocation else {
			throw LocationError.LocationNotAvailable
		}
		LocationManager.shared.reverseLocation(location: loc, onSuccess: sHandler, onError: fHandler)
	}
	
}
