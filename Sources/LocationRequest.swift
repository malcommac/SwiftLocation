/*
* SwiftLocation
* Easy and Efficent Location Tracker for Swift
*
* Created by:	Daniele Margutti
* Email:		hello@danielemargutti.com
* Web:			http://www.danielemargutti.com
* Twitter:		@danielemargutti
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/

import Foundation
import CoreLocation
import MapKit

public class LocationRequest: Request, Equatable, Hashable {
	
	/// Typealias for success handler
	public typealias Success = ((CLLocation) -> (Void))
	
	/// Typealias for failure handler
	public typealias Failure = ((_ error: LocationError, _ location: CLLocation?) -> (Void))
	
	/// Type of operation of the request
	///
	/// - oneshot: one shot; request will be stopped when a a success or failure is triggered.
	/// - continous: continous request will continue until manual stop is called
	/// - significant: only significant changes
	public enum Mode {
		case oneshot
		case continous
		case significant
	}
	
	/// Last achieved location for this request.
	public internal(set) var location: CLLocation? = nil
	
	/// Callback called on success
	internal var success: Success? = nil
	
	/// Callback called on failure
	internal var failure: Failure? = nil
	
	/// Operation mode the request
	public private(set) var mode: Mode
	
	/// Unique identifier of the request
	public private(set) var id: RequestID = UUID().uuidString
	
	/// Accuracy of the request
	public private(set) var accuracy: Accuracy
	
	/// Timeout manager
	public private(set) var timeout: TimeoutManager?
	
	/// Return the interval set for timeout
	public var timeoutInterval: TimeInterval? {
		return timeout?.value
	}
	
	/// Returns whether this is a subscription request or not
	public var isRecurring: Bool {
		return (self.mode == .continous || self.mode == .significant)
	}
	
	/// Initialize a new location request with given paramters.
	/// You don't need to allocate your own request, just user the `Location` functions.
	///
	/// - Parameters:
	///   - accuracy: desidered accuracy of the request
	///   - timeout: timeout of the request, `nil` if timeout should not be considered.
	internal init(mode: Mode, accuracy: Accuracy, timeout: Timeout?) {
		self.mode = mode
		self.accuracy = accuracy
		self.timeout = TimeoutManager(timeout, callback: {
			Locator.locationRequestDidTimedOut(self)
		})
	}
	
	/// Set the timeout interval of the request.
	///
	/// - Parameter timeout: timeout, `nil` to ignore timeout (manual stop is required)
	/// - Returns: self
	public func timeout(_ timeout: Timeout?) -> Self {
		self.timeout = TimeoutManager(timeout, callback: {
			Locator.locationRequestDidTimedOut(self)
		})
		return self
	}
	
	/// Stop running request
	public func stop() {
		Locator.stopRequest(self)
	}
	
	/// Passed location has valid results for current request
	///
	/// - Parameter location: location to verify
	/// - Returns: `true` if values from location are valid for this request
	internal func hasValidThrehsold(forLocation location: CLLocation) -> Bool {
		// This is a regular one-time location request
		let lastUpdateTime = fabs(location.timestamp.timeIntervalSinceNow)
		let lastAccuracy = location.horizontalAccuracy
		if (lastUpdateTime <= self.accuracy.timeStaleThreshold &&
			lastAccuracy <= self.accuracy.threshold) {
			return true
		}
		return false
	}

	/// Return the error status of the request, if any
	internal var error: LocationError? {
		switch Locator.manager.serviceState {
		case .disabled:
			return .disabled
		case .notDetermined:
			return .notDetermined
		case .denied:
			return .denied
		case .restricted:
			return .restricted
		default:
			if Locator.updateFailed == true {
				return .error
			} else if self.timeout?.hasTimedout ?? false {
				return .timedout
			}
			return nil
		}
	}
	
	public static func ==(lhs: LocationRequest, rhs: LocationRequest) -> Bool {
		return lhs.id == rhs.id
	}
	
	public var hashValue: Int {
		return self.id.hashValue
	}
}
