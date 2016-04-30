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
import MapKit

public class LocationRequest: LocationManagerRequest {
		/// Handler called on error
	internal var onErrorHandler: LocationHandlerError?
		/// Handler called on success
	internal var onSuccessHandler: LocationHandlerSuccess?
		/// Handler called on pauses
	internal var onPausesHandler: LocationHandlerPaused?
		/// Timeout timer
	private var timeoutTimer: NSTimer?
		/// Unique identifier of the request
	internal var UUID: String = NSUUID().UUIDString
		/// Enable/disable ability of the request object to receive updates when into the queue
	internal var isEnabled: Bool = true {
		didSet {
			let shouldEnable = isEnabled
			self.setTimeoutTimer(shouldEnable)
		}
	}
	
	/// Type of activity to monitor.
	/// The location manager uses the information in this property as a cue to determine when location updates may be automatically paused
	public var activityType: CLActivityType = .Other {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	
		/// Interval of time before a request is removed from the queue.
		/// Timeout timer starts when a location manager authorization appears on screen
		/// and when a request receive a new update. If no new updates are received inside this interval
		/// request will be aborted.
		/// A nil value means "do not use timeout".
	public var timeout: NSTimeInterval? = nil
	
		/// This is the last location received for this request. Maybe nil if any valid request is received yet.
	private(set) var lastLocation: CLLocation?
	
		/// This is the frequency internval you want to receive updates about this monitor session
	public var frequency: UpdateFrequency = .Continuous {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	
		/// This is the accuracy of location you consider valid for this monitor session
	public var accuracy: Accuracy = .City {
		didSet {
			LocationManager.shared.updateLocationUpdateService()
		}
	}
	
	/**
	Initialize a new request with desidered accuracy and frequency. Request must be added to the queue to be valid.
	
	- parameter accuracy:  accuracy you want to receive
	- parameter frequency: updates frequency you want to get
	
	- returns: a new request
	*/
	public init(withAccuracy accuracy: Accuracy, andFrequency frequency: UpdateFrequency) {
		self.accuracy = accuracy
		self.frequency = frequency
	}
	
	/**
	Chainable function you can use to set the error handler to execute when something goes wrong while receiving updates from location manager
	
	- parameter err: handler to call
	
	- returns: return self instance in order to perform a chain of handlers
	*/
	public func onError(err: LocationHandlerError) -> LocationRequest {
		self.onErrorHandler = err
		return self
	}
	
	/**
	Chainable function you use to set the success handler to execute when a new location has been found
	
	- parameter succ: success handler to call
	
	- returns: return self instance in order to perform a chain of handlers
	*/
	public func onSuccess(succ: LocationHandlerSuccess) -> LocationRequest {
		self.onSuccessHandler = succ
		return self
	}
	
	/**
	Chainable function you can use to set the handler called when location manager pauses location updates in order to keep low
	battery usage (you should set the activityType to allow the system to know when it's time to pause the location manager updates because
	it's not likely to change)
	
	- parameter handler: handler to call
	
	- returns: return self instance in order to perform a chain of handlers
	*/
	public func onPause(handler: LocationHandlerPaused) -> LocationRequest {
		self.onPausesHandler = handler
		return self
	}
	
	/**
	Stop receiving updates for this request and remove it from queue
	*/
	public func stop() {
		self.isEnabled = false
		self.setTimeoutTimer(false)
		LocationManager.shared.stopObservingLocation(self)
	}
	
	/**
	Temporary pauses receiving updates for this request. Request is not removed from the queue and you can resume it using start()
	*/
	public func pause() {
		self.isEnabled = false
		LocationManager.shared.updateLocationUpdateService()
	}
	
	/**
	Start (or restart) a request
	*/
	public func start() {
		self.isEnabled = true
		LocationManager.shared.addLocationRequest(self)
	}
	
	//MARK: - Private Methods
	
	internal func setTimeoutTimer(start: Bool) {
		if let _ = self.timeoutTimer {
			self.timeoutTimer!.invalidate()
			self.timeoutTimer = nil
		}
		guard start == true, let interval = self.timeout else { return }
		self.timeoutTimer = NSTimer(timeInterval: interval, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
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
			self.setTimeoutTimer(true)
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
