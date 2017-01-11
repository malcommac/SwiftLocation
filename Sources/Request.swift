//
//  Request.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

public protocol Request: class, Hashable, Equatable {
	
	func resume() -> Bool
	func pause() -> Bool
	func cancel() -> Bool
	
	var state: RequestState { get }
}


/// This represent the state of a request
///
/// - idle: an idle request is not part of the main location queue. It's the initial state of a request before.
/// - waitingUserAuth: this is a paused state. Request is running but actually it's paused waiting for user authorization.
/// - running: a running request can receive events about location manager
/// - paused: a paused request its part of the location queue but does not receive events
/// - failed: a failed request its a request
public enum RequestState {
	case idle
	case waitingUserAuth
	case running
	case paused
	case failed
	
	public var isRunning: Bool {
		switch self {
		case .running, .failed:
			return true
		default:
			return false
		}
	}
	
	public var isPaused: Bool {
		switch self {
		case .waitingUserAuth, .paused, .failed(_):
			return true
		default:
			return false
		}
	}
}


/// Location events callbacks
///
/// - onReceiveLocation: on receive new location callback
/// - onErrorOccurred: on receive an error callback
public enum LocCallback {
	public typealias onSuccess = ((_ location: CLLocation) -> (Void))
	public typealias onError = ((_ lastLocation: CLLocation? , _ error: Error) -> (Void?))
	
	case onReceiveLocation(_: Context, _: onSuccess)
	case onErrorOccurred(_: Context, _: onError)
}

public final class LocationRequest: Request {
	
	public typealias OnSuccessCallback = ((_ location: CLLocation) -> (Void))
	public typealias OnErrorCallback = ((_ lastLocation: CLLocation? , _ error: Error) -> (Void?))
	public typealias OnAuthDidChangeCallback = ((_ old: CLAuthorizationStatus, _ new: CLAuthorizationStatus) -> (Void))
	
	private(set) var frequency: Frequency
	private(set) var accuracy:	Accuracy
	public var activity: CLActivityType = .other {
		didSet {
			Location.updateLocationServices()
		}
	}

	
	/// Set a valid interval to enable a timer. Timeout starts automatically
	private var timeoutTimer: Timer?
	public var timeout: TimeInterval? = nil {
		didSet {
			timeoutTimer?.invalidate()
			timeoutTimer = nil
			guard let interval = self.timeout else {
				return
			}
			self.timeoutTimer = Timer.scheduledTimer(timeInterval: interval,
			                                         target: self,
			                                         selector: #selector(timeoutTimerFired),
			                                         userInfo: nil,
			                                         repeats: false)
		}
	}
	
	@objc func timeoutTimerFired() {
		self.dispatchError(LocationError.timeout)
	}
	
	private(set) var lastLocation: CLLocation?
	private(set) var lastError: Error?
	
	/// Unique identifier of the request
	private var identifier: String = NSUUID().uuidString
	
	/// `true` to remove from location queue the request itself if receive an error or timeout
	public var cancelOnError: Bool = false
	
	/// This represent the current state of the Request
	internal(set) var _state: RequestState = .idle
	public var state: RequestState {
		get {
			return self._state
		}
	}
	
	/// Callbacks registered
	public var registeredCallbacks: [LocCallback] = []
	
	/// This callback is called when Location Manager authorization state did change
	public var authChangeCallbacks: [OnAuthDidChangeCallback] = []
	
	/// Initialize a new `Request` with passed settings. In order to start it you should call `resume()`
	/// function. You can also avoid direct `Request` init and use `Location` built-in functions.
	///
	/// - Parameters:
	///   - accuracy: accuracy of the location measure
	///   - frequency: frequency of updates for location meause
	///   - success: callback called when a new location has been received
	///   - error: callback called when an error has been received
	public init(accuracy: Accuracy, frequency: Frequency,
	            _ success: @escaping LocCallback.onSuccess, _ error: LocCallback.onError? = nil) {
		self.accuracy = accuracy
		self.frequency = frequency
		
		self.registeredCallbacks.append(LocCallback.onReceiveLocation(.main, success))
		if error != nil {
			self.registeredCallbacks.append(LocCallback.onErrorOccurred(.main, error!))
		}
		self._state = (self.isBackgroundRequest ? .paused : .idle)
	}
	
	/// Resume a paused request or add a new request in queue and start it.
	///
	/// - Returns: `true` if request has been started, `false` otherwise
	@discardableResult
	public func resume() -> Bool {
		
		let isAppInBackground = (UIApplication.shared.applicationState == .background)
		let canStart = (isAppInBackground && self.isBackgroundRequest) || (!isAppInBackground && !self.isBackgroundRequest)
		guard canStart == true else {
			return false // cannot be started
		}
		
		if self.isInQueue {
			guard self.state.isPaused == true else { // if not paused we can't change the state
				return false
			}
			// start a new request
			self._state = .running
			return true
		} else {
			// if not in queue this function register a new request
			self._state = .running
			Location.start(self)
			return true
		}
	}
	
	/// Pause a running request.
	///
	/// - Returns: `true` if request is paused, `false` otherwise.
	@discardableResult
	public func pause() -> Bool {
		guard self.state.isRunning else {
			return false
		}
		self._state = .paused
		return true
	}
	
	/// Cancel a running request and remove it from queue.
	///
	/// - Returns: `true` if request was removed successfully, `false` otherwise.
	@discardableResult
	public func cancel() -> Bool {
		guard self.isInQueue else {
			return false
		}
		self._state = .idle
		Location.cancel(self)
		return true
	}
	
	/// `true` if request is on location queue
	internal var isInQueue: Bool {
		return Location.isQueued(self) == true
	}
	
	/// `true` if request works in background app state
	internal var isBackgroundRequest: Bool {
		switch self.frequency {
		case .backgroundUpdate(_,_):
			return true
		default:
			return false
		}
	}
	
	/// Implementation of the hash function
	public var hashValue: Int {
		return identifier.hash
	}
	
	//MARK: Events from Location Dispatcher
	
	
	/// Receiver for new location event. This message is passed directly from Location Manager
	/// and should be not modified.
	///
	/// - Parameter location: location received from system
	internal func dispatchLocation(_ location: CLLocation?) {
		// if request is paused or location is nil we want to discard this event
		guard self.state.isRunning, let loc = location else { return }
		// if received location is not valid in accuracy we want to discard this event
		guard accuracy.isValid(loc) else { return }
		
		if let settings = Location.locationSettings, let lastLocation = self.lastLocation {
			if case .whenTravelled(let minDist, let minTime) = self.frequency {
				if settings.frequency.isTravelledFrequency {
					// If our location manager is not set to receive locations at fixed amount of
					// travelled distance or time (because due to some other requests there is an higher resolution)
					// we need to simulate it by discarding manually data.
					let timePassed = (loc.timestamp.timeIntervalSince(lastLocation.timestamp) >= minTime) // enough time is passed
					let distancePassed = (loc.distance(from: lastLocation) >= minDist) // enough distance is passed
					if distancePassed == false && timePassed == false {
						return // ignore
					}
				}
			}
		}
		
		// store last valid location an dispatch it to call
		self.lastLocation = loc
		self.registeredCallbacks.forEach {
			if case .onReceiveLocation(let context, let handler) = $0 {
				context.queue.async { handler(loc) }
			}
		}
		if case .oneShot = self.frequency { // if one shot we can cancel and remove it
			self.cancel()
		}
	}

	
	/// Internal receiver for status change event
	///
	/// - Parameter status: new status
	internal func dispatchAuthChange(_ old: CLAuthorizationStatus, _ new: CLAuthorizationStatus) {
		guard self.state.isRunning else { return }
		self.authChangeCallbacks.forEach { $0(old,new) }
	}
	
	
	/// Internal receiver for errors
	/// When an error is received if `cancelOnError` is `true` request is also removed from queue and transit to `failed` state.
	///
	/// - Parameter error: error received
	internal func dispatchError(_ error: Error) {
		guard self.state.isRunning else { return } // ignore if not running
		// Alert callbacks
		self.lastError = error
		self.registeredCallbacks.forEach {
			if case .onErrorOccurred(let context, let handler) = $0 {
				context.queue.async { handler(self.lastLocation,error) }
			}
		}
		
		if self.cancelOnError == true { // remove from main location queue
			self.cancel()
			self._state = .failed
		}
	}
}

public func ==(lhs: LocationRequest, rhs: LocationRequest) -> Bool {
	return lhs.hashValue == rhs.hashValue
}
