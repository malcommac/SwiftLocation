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

public class HeadingRequest: Request {
		/// Unique identifier of the heading request
	public var UUID: String = NSUUID().UUIDString
		/// Handler to call when a new heading value is received
	internal var onReceiveUpdates: HeadingHandlerSuccess?
		/// Handler to call when an error has occurred
	internal var onError: HeadingHandlerError?
		/// Authorization did change
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange?
	
		/// Last heading received
	private(set) var lastHeading: CLHeading?
	
	internal weak var locator: LocationManager?
	
	public var rState: RequestState = .Pending {
		didSet {
			self.locator?.updateHeadingService()
		}
	}
	
	/// Frequency value to receive new events
	public var frequency: HeadingFrequency {
		didSet {
			self.locator?.updateHeadingService()
		}
	}
	
	/// The maximum deviation (measured in degrees) between the reported heading and the true geomagnetic heading.
	public var accuracy: CLLocationDirection {
		didSet {
			self.locator?.updateHeadingService()
		}
	}
	
	/// True if system calibration tool can be opened if necessary.
	public var allowsCalibration: Bool = true
	
	/**
	Create a new request to receive heading values from device's motion sensors about the orientation of the device
	
	- parameter withInterval: The minimum angular change (measured in degrees) required to generate new heading events.If nil is specified you will receive any new value
	- parameter sHandler:     handler to call when a new heading value is received
	- parameter eHandler:     error handler to call when something goes bad. request is automatically stopped and removed from queue.
	
	- returns: the request instance you can add to the queue
	*/
	
	internal init(withFrequency frequency: HeadingFrequency, accuracy: CLLocationDirection, allowsCalibration: Bool = true) {
		self.frequency = frequency
		self.accuracy = accuracy
		self.allowsCalibration = allowsCalibration
	}
	
	/**
	Use this function to change the handler to call when a new heading value is received
	
	- parameter handler: handler to call
	
	- returns: self, used to make the function chainable
	*/
	public func onReceiveUpdates(handler :HeadingHandlerSuccess) -> HeadingRequest {
		self.onReceiveUpdates = handler
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
	Put the request in queue and starts it
	*/
	public func start() {
		guard let locator = self.locator else { return }
		let previousState = self.rState
		self.rState = .Running
		if locator.add(self) == false {
			self.rState = previousState
		}
	}
	
	/**
	Temporary pause request (not removed)
	*/
	public func pause() {
		if self.rState.isRunning {
			guard let locator = self.locator else { return }
			self.rState = .Paused
			locator.updateHeadingService()
		}
	}
	
	/**
	Terminate request
	*/
	public func cancel(error: LocationError?) {
		guard let locator = self.locator else { return }
		if locator.remove(self) {
			self.rState = .Cancelled(error: error)
		}
	}
	
	/**
	Terminate request without errors
	*/
	public func cancel() {
		self.cancel(nil)
	}
	
	//MARK: - Private
	
	internal func didReceiveEventFromManager(error: NSError?, heading: CLHeading?) {
		if error != nil {
			let err = LocationError.LocationManager(error: error!)
			self.onError?(err)
			self.cancel(err)
			return
		}
		
		if self.validateHeading(heading!) == true {
			self.lastHeading = heading
			if self.rState.isRunning == true {
				self.onReceiveUpdates?(self.lastHeading!)
			}
		}
	}
	
	private func validateHeading(heading: CLHeading) -> Bool {
		guard let lastHeading = self.lastHeading else {
			return true
		}
		
		switch self.frequency {
		case .Continuous(let interval):
			let elapsedTime = (heading.timestamp.timeIntervalSince1970 - lastHeading.timestamp.timeIntervalSince1970)
			return (elapsedTime > interval)
		case .MagneticNorth(let minChange):
			let degreeDiff = fabs(heading.magneticHeading - lastHeading.magneticHeading)
			return (degreeDiff > minChange)
		case .TrueNorth(let minChange):
			let degreeDiff = fabs(heading.trueHeading - lastHeading.trueHeading)
			return (degreeDiff > minChange)
		}
	}

}