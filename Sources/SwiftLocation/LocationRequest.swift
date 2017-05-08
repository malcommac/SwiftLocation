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
import MapKit
import CoreLocation

/// Location events callbacks
///
/// - onReceiveLocation: on receive new location callback
/// - onErrorOccurred: on receive an error callback
/// - onAuthDidChange: on receive a change in authorization status
public enum LocObserver {
	public typealias onSuccess = ((_ request: LocationRequest, _ location: CLLocation) -> (Void))
	public typealias onError = ((_ request: LocationRequest, _ lastLocation: CLLocation? , _ error: Error) -> (Void))
	public typealias onAuthChange = ((_ request: LocationRequest, _ old: CLAuthorizationStatus , _ new: CLAuthorizationStatus) -> (Void))
	
	case onReceiveLocation(_: Context, _: onSuccess)
	case onErrorOccurred(_: Context, _: onError)
	case onAuthDidChange(_: Context, _: onAuthChange)
}

public class LocationRequest: Request {
	
	/// Desidered frequency of the updates
	private(set) var frequency: Frequency
	
	/// Desidered accuracy
	private(set) var accuracy:	Accuracy
	
	/// Type of activity.
	/// It indicate the type of activity associated with location updates and helps the system to set best value
	/// for energy efficency.
	public var activity: CLActivityType = .other {
		didSet {
			Location.updateLocationServices()
		}
	}
	
	/// Assigned request name, used for your own convenience
	public var name: String?
	
	/// Description of the request
	public var description: String {
		let name = (self.name ?? self.identifier)
		return "[LOC:\(name)] - Acc=\(accuracy), Fq=\(frequency). (Status=\(self.state), Queued=\(self.isInQueue))"
	}

	/// Timeout timer
	private var timeoutTimer: Timer?

	/// Set a valid interval to enable a timer. Timeout starts automatically
	public var timeout: TimeInterval? = nil
	
	/// The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
	/// This value is ignored when request is has `significant` frequency set.
	/// Set it to `nil` to report all movements.
	public var minimumDistance: CLLocationDistance? = nil
	
	/// Last valid meaured location
	private(set) var lastLocation: CLLocation?
	
	/// Last received error
	private(set) var lastError: Error?
	
	/// Unique identifier of the request
	private var identifier: String = NSUUID().uuidString
	
	/// `true` to remove from location queue the request itself if receive an error or timeout.
	/// By default is `false`.
	public var cancelOnError: Bool = false
	
	/// This represent the current state of the Request
	internal var _previousState: RequestState = .idle
	internal(set) var _state: RequestState = .idle {
		didSet {
			if _previousState != _state {
				onStateChange?(_previousState,_state)
				_previousState = _state
			}
		}
	}
	public var state: RequestState {
		get {
			return self._state
		}
	}
	
	/// Callback to call when request's state did change
	public var onStateChange: ((_ old: RequestState, _ new: RequestState) -> (Void))?
	
	/// Callbacks registered
	public var registeredCallbacks: [LocObserver] = []
	
	/// This callback is called when Location Manager authorization state did change
	//public var authChangeCallbacks: [OnAuthDidChangeCallback] = []
	
	/// Initialize a new `Request` with passed settings. In order to start it you should call `resume()`
	/// function. You can also avoid direct `Request` init and use `Location` built-in functions.
	///
	/// - Parameters:
	///   - accuracy: accuracy of the location measure
	///   - frequency: frequency of updates for location meause
	///   - success: callback called when a new location has been received
	///   - error: callback called when an error has been received
	public init(name: String? = nil, accuracy: Accuracy, frequency: Frequency,
	            _ success: @escaping LocObserver.onSuccess, _ error: LocObserver.onError? = nil) {
		self.name = name
		self.accuracy = accuracy
		if case .IPScan(_) = accuracy {
			// If accuracy is IP Scan we will ignore frequency, always oneShot is set
			self.frequency = .oneShot
		} else {
			self.frequency = frequency
		}
		
		self.register(observer: LocObserver.onReceiveLocation(.main, success))
		if error != nil {
			self.register(observer: LocObserver.onErrorOccurred(.main, error!))
		}
	}
	
	public func register(observer: LocObserver) {
		self.registeredCallbacks.append(observer)
	}
	
	/// Resume a paused request or add a new request in queue and start it.
	///
	/// - Returns: `true` if request has been started, `false` otherwise
	public func resume() {
		Location.start(self)
	}
	
	/// Pause a running request.
	///
	/// - Returns: `true` if request is paused, `false` otherwise.
	public func pause() {
		self.stopTimeout()
		Location.pause(self)
	}
	
	/// Cancel request and remove it from queue.
	public func cancel() {
		self.stopTimeout()
		Location.cancel(self)
	}

	/// `true` if request is on location queue
	public var isInQueue: Bool {
		return Location.isQueued(self) == true
	}
	
	/// `true` if request works in background app state
	public var isBackgroundRequest: Bool {
		switch self.frequency {
		case .deferredUntil(_,_,_):
			return true
		default:
			return false
		}
	}
	
	public var requiredAuth: Authorization {
		if case .IPScan(_) = self.accuracy {
			return .none
		}
		switch self.frequency {
		case .deferredUntil(_,_,_), .significant:
			return .always
		default:
			return .inuse
		}
	}
	
	/// Implementation of the hash function
	public var hashValue: Int {
		return identifier.hash
	}
	
	//MARK: Timeout Support
	
	/// Start timeout timer if a valid interval is specified.
	/// Does nothing if not specified
	private func startTimeout() {
		stopTimeout()
		guard let interval = self.timeout else { return }
		self.timeoutTimer = Timer.scheduledTimer(timeInterval: interval,
		                                         target: self,
		                                         selector: #selector(timeoutTimerFired),
		                                         userInfo: nil,
		                                         repeats: false)
	}
	
	
	/// Stop timeout timer
	private func stopTimeout() {
		timeoutTimer?.invalidate()
		timeoutTimer = nil
	}
	
	@objc func timeoutTimerFired() {
		self.dispatch(error: LocationError.timeout)
		
		// If continous location restart timer
		if self.cancelOnError == false {
			self.startTimeout()
		}
	}
	
	//MARK: Events from Location Dispatcher
	
	
	/// Receiver for new location event. This message is passed directly from Location Manager
	/// and should be not modified.
	///
	/// - Parameter location: location received from system
	internal func dispatch(location: CLLocation?) {
		// if request is paused or location is nil we want to discard this event
		guard let loc = location else { return }
		// if received location is not valid in accuracy we want to discard this event
		guard accuracy.isValid(loc) else { return }
		
		// Validate request's accuracy
		guard accuracy.isValid(loc) else { return }
		// Validate minimum distance (if set)
		guard isValidMinimumDistance(loc) else { return }
		
		// store last valid location an dispatch it to call
		self.lastLocation = loc
		self.registeredCallbacks.forEach {
			if case .onReceiveLocation(let context, let handler) = $0 {
				context.queue.async { handler(self,loc) }
			}
		}
		
		// Remove request from queue if some conditions are verified
		if stopRequestIfNeeded() == false {
			// Stop and restart timeout timer if needed
			startTimeout()
		}
	}
	
	private func isValidMinimumDistance(_ loc: CLLocation) -> Bool {
		// no filter by distance is applied, check passed
		guard let lastLoc = self.lastLocation, let minDistance = self.minimumDistance else { return true }
		// check horizontal distance
		return (loc.distance(from: lastLoc) > minDistance)
	}

	
	/// Stop request according to settings
	///
	/// - Returns: `true` if request was stopped, `false` otherwise
	@discardableResult
	private func stopRequestIfNeeded() -> Bool {
		var willStop = false
		defer {
			if willStop {
				self.cancel()
			}
		}
		
		if case .oneShot = self.frequency {
			// if one shot we can cancel and remove it
			willStop = true
		}
		if case .IPScan(_) = self.accuracy {
			// IP Scan services are one shot too
			willStop = true
		}
		return willStop
	}
	
	/// Internal receiver for status change event
	///
	/// - Parameter status: new status
	internal func dispatchAuthChange(_ old: CLAuthorizationStatus, _ new: CLAuthorizationStatus) {
		self.registeredCallbacks.forEach { callback in
			if case .onAuthDidChange(let context, let handler) = callback {
				context.queue.async { handler(self,old,new) }
			}
		}
	}
	
	/// Internal receiver for errors
	/// When an error is received if `cancelOnError` is `true` request is also removed from queue and transit to `failed` state.
	///
	/// - Parameter error: error received
	public func dispatch(error: Error) {
		// Alert callbacks
		self.registeredCallbacks.forEach {
			if case .onErrorOccurred(let context, let handler) = $0 {
				context.queue.async { handler(self,self.lastLocation,error) }
			}
		}
		
		if self.cancelOnError == true || self.frequency == .oneShot { // remove from main location queue
			self.cancel()
			self._state = .failed(error)
		}
	}
	
	public func onResume() {
		self.startTimeout() // start timer for timeout if necessary
		switch self.accuracy {
		case .IPScan(_):
			self.executeIPLocationRequest() // execute request
		default:
			break
		}
	}
	
	public func onPause() { }
	
	public func onCancel() { }
	
	//MARK: IP Location Extensions
	
	internal func executeIPLocationRequest() {
		guard case .IPScan(let service) = self.accuracy else {
			return
		}
		service.getLocationFromIP(success: {
			self.stopTimeout() // stop timeout timer
			self.dispatch(location: $0)
		}) {
			self.stopTimeout() // stop timeout timer
			self.dispatch(error: $0!)
		}
	}
}

public func ==(lhs: LocationRequest, rhs: LocationRequest) -> Bool {
	return lhs.hashValue == rhs.hashValue
}
