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

public class LocationRequest: Request  {
		/// Handler called on error
	internal var onErrorHandler: LocationHandlerError?
		/// Handler called on success
	internal var onSuccessHandler: LocationHandlerSuccess?
		/// Handler called on pauses
	internal var onPausesHandler: LocationHandlerPaused?
		/// Timeout timer
	private var timeoutTimer: Timer?
		/// Unique identifier of the request
	public var UUID: String = Foundation.UUID().uuidString
		/// Enable/disable ability of the request object to receive updates when into the queue
	internal var isEnabled: Bool = false {
		didSet {
			let shouldEnable = isEnabled
			self.setTimeoutTimer(shouldEnable)
		}
	}
	
	/// Type of activity to monitor.
	/// The location manager uses the information in this property as a cue to determine when location updates may be automatically paused
	public var activityType: CLActivityType = .other {
		didSet {
			Location.updateLocationUpdateService()
		}
	}
	
		/// Interval of time before a request is removed from the queue.
		/// Timeout timer starts when a location manager authorization appears on screen
		/// and when a request receive a new update. If no new updates are received inside this interval
		/// request will be aborted.
		/// A nil value means "do not use timeout".
	public var timeout: TimeInterval? = nil
	
		/// This is the last location matching the requested accuracy received for this request. Maybe nil if any valid request is received yet.
	private(set) var lastValidLocation: CLLocation?
    
        /// This is the last location received for this request which might not match requested accuracy. Maybe nil if any valid request is received yet.
    private(set) var lastLocation: CLLocation?
	
		/// This is the frequency internval you want to receive updates about this monitor session
	public var frequency: UpdateFrequency = .continuous {
		didSet {
			Location.updateLocationUpdateService()
		}
	}
	
		/// This is the accuracy of location you consider valid for this monitor session
	public var accuracy: Accuracy = .city {
		didSet {
			Location.updateLocationUpdateService()
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
	public func onError(_ err: LocationHandlerError) -> LocationRequest {
		self.onErrorHandler = err
		return self
	}
	
	/**
	Chainable function you use to set the success handler to execute when a new location has been found
	
	- parameter succ: success handler to call
	
	- returns: return self instance in order to perform a chain of handlers
	*/
	public func onSuccess(_ succ: LocationHandlerSuccess) -> LocationRequest {
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
	public func onPause(_ handler: LocationHandlerPaused) -> LocationRequest {
		self.onPausesHandler = handler
		return self
	}

	/**
	Terminate request
	*/
	public func cancel() {
		self.isEnabled = false
		self.setTimeoutTimer(false)
		Location.stopLocationRequest(self)
	}
	
	/**
	Temporary pauses receiving updates for this request. Request is not removed from the queue and you can resume it using start()
	*/
	public func pause() {
		self.isEnabled = false
		Location.updateLocationUpdateService()
	}
	
	/**
	Start (or restart) a request
	*/
	public func start() {
		self.isEnabled = true
		let _ = Location.addLocationRequest(self)
	}
	
	//MARK: - Private Methods
	
	internal func setTimeoutTimer(_ shouldStart: Bool) {
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
        
		guard let interval = self.timeout , shouldStart else { return }
		self.timeoutTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
	}
	
	@objc func timeoutTimerFired() {
        self.onErrorHandler?(self.lastLocation, LocationError.requestTimeout)
		
        self.cancel()
	}
	
	internal func didReceiveEventFromLocationManager(error: LocationError?, location: CLLocation?) -> Bool {
		if let error = error {
			self.onErrorHandler?(location, error)
			self.cancel()
			return true
		}
		
		if let location = location {
			if self.isValidLocation(location) == false {
				return false
			}
			self.lastValidLocation = location
			self.onSuccessHandler?(self.lastValidLocation!)
			if self.frequency == .oneShot {
				self.cancel()
			}else if self.frequency == .continuous{
				// if location is valid and is required in continuous frequency
				self.setTimeoutTimer(true)
			}else{
				// if location is required to be updated by distance interval or by significant distance,
				// don't use timeout as no one can predict when the distance will change and thus canceling the request would
				// prevent any future move to trigger the update.
				// It's on client app's responsibility to cancel request if it decided that too much time elapsed between two updates.
				// Also "pause" should be used instead of "cancel" in these cases as cancel makes the request impossible to restart.
				// So timeout timer is only used until the first update. Then it's canceled.
				self.setTimeoutTimer(false)
			}
			
			return true
		}
		
		return false
	}
	
	internal func isValidLocation(_ loc: CLLocation) -> Bool {
        self.lastLocation = loc
		
		if self.accuracy.isLocationValidForAccuracy(obj: loc) == false {
			return false
		}
		
		if let lastValidLocation = self.lastValidLocation {
			if case .byDistanceIntervals(let meters) = self.frequency {
				let distanceSinceLastReport = lastValidLocation.distance(from: loc)
				if distanceSinceLastReport < meters {
					return false
				}
			}
		}
		
		let afterLastValidLocation = (self.lastValidLocation == nil ? true : loc.timestamp.timeIntervalSince1970 >= self.lastValidLocation!.timestamp.timeIntervalSince1970)
		if afterLastValidLocation == false {
			return false
		}
		
		return true
	}
	
}
