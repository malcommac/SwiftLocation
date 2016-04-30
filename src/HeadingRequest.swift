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

public class HeadingRequest: LocationManagerRequest {
		/// Unique identifier of the heading request
	internal var UUID: String = NSUUID().UUIDString
		/// Handler to call when a new heading value is received
	internal var onSuccess: HeadingHandlerSuccess?
		/// Handler to call when an error has occurred
	internal var onError: HeadingHandlerError?
		/// Handler to call when a new device's calibration is required
	internal var onCalibrationRequired: HeadingHandlerCalibration?
	
		/// Last heading received
	private(set) var lastHeading: CLHeading?
	
	// Private variables
	
	internal var isEnabled: Bool = true {
		didSet {
			LocationManager.shared.updateHeadingService()
		}
	}
	
		/// The minimum angular change (measured in degrees) required to generate new heading events. If nil is specified you
		/// will receive any new value
	public var degreesInterval: CLLocationDegrees? = 1 {
		didSet {
			LocationManager.shared.updateHeadingService()
		}
	}
	
	/**
	Create a new request to receive heading values from device's motion sensors about the orientation of the device
	
	- parameter withInterval: The minimum angular change (measured in degrees) required to generate new heading events.If nil is specified you will receive any new value
	- parameter sHandler:     handler to call when a new heading value is received
	- parameter eHandler:     error handler to call when something goes bad. request is automatically stopped and removed from queue.
	
	- returns: the request instance you can add to the queue
	*/
	public init(withInterval: CLLocationDegrees = 1, onSuccess sHandler: HeadingHandlerSuccess?, onError eHandler: HeadingHandlerError?) {
		self.onSuccess = sHandler
		self.onError = eHandler
	}
	
	/**
	Use this function to change the handler to call when a new heading value is received
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onSuccess(handler :HeadingHandlerSuccess) -> HeadingRequest {
		self.onSuccess = handler
		return self
	}
	
	/**
	Use this function to change the handler to call when something bad occours while receiving data from server
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onError(handler :HeadingHandlerError) -> HeadingRequest {
		self.onError = handler
		return self
	}
	
	/**
	Use this function to change the handler to call when device calibration is required. You must return true or false
	at the end of this handler. If at least one request return true to this handler the calibration window will be opened
	automatically.
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onCalibrationRequired(handler :HeadingHandlerCalibration?) -> HeadingRequest {
		self.onCalibrationRequired = handler
		return self
	}
	
	/**
	Put the request in queue and starts it
	*/
	public func start() {
		self.isEnabled = true
		LocationManager.shared.addHeadingRequest(self)
	}
	
	/**
	Stop this request if running
	*/
	public func stop() {
		self.isEnabled = false
		LocationManager.shared.stopObservingHeading(self)
	}
	
	/**
	Temporary pause request (not removed)
	*/
	public func pause() {
		self.isEnabled = false
	}
	
	//MARK: - Private
	
	internal func didReceiveEventFromManager(error: NSError?, heading: CLHeading?) {
		if error != nil {
			self.onError?(LocationError.LocationManager(error: error!))
			self.stop()
			return
		}
		
		if self.validateHeading(heading!) == true {
			self.lastHeading = heading
			self.onSuccess?(self.lastHeading!)
		}
	}
	
	private func validateHeading(heading: CLHeading) -> Bool {
		guard let lastHeading = self.lastHeading else { return true }
		
		if heading.timestamp.timeIntervalSince1970 <= lastHeading.timestamp.timeIntervalSince1970 {
			return false
		}
		
		guard let degreesInterval = self.degreesInterval else { return true }
		return (fabs( Double(heading.headingAccuracy-lastHeading.headingAccuracy) ) > degreesInterval)
	}
}