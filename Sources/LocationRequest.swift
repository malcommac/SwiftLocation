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

public class LocationRequest: Request {
	
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
		self.dispatch(error: LocationError.timeout)
	}
	
	private(set) var lastLocation: CLLocation?
	private(set) var lastError: Error?
	
	/// Unique identifier of the request
	private var identifier: String = NSUUID().uuidString
	
	/// `true` to remove from location queue the request itself if receive an error or timeout
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
		if case .IPScan(_) = accuracy {
			// If accuracy is IP Scan we will ignore frequency, always oneShot is set
			self.frequency = .oneShot
		} else {
			self.frequency = frequency
		}
		
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
	public func resume() {
		Location.start(self)
	}
	
	/// Pause a running request.
	///
	/// - Returns: `true` if request is paused, `false` otherwise.
	@discardableResult
	public func pause() {
		Location.pause(self)
	}
	
	/// Cancel a running request and remove it from queue.
	@discardableResult
	public func cancel() {
		Location.cancel(self)
	}
	
	/// `true` if request is on location queue
	internal var isInQueue: Bool {
		return Location.isQueued(self) == true
	}
	
	/// `true` if request works in background app state
	internal var isBackgroundRequest: Bool {
		switch self.frequency {
		case .whenTravelled(_,_):
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
	internal func dispatch(location: CLLocation?) {
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
	internal func dispatch(error: Error?) {
		guard let error = error, self.state.isRunning else { return } // ignore if not running
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
	
	public func onResume() {
		switch self.accuracy {
		case .IPScan(_):
			self.executeIPLocationRequest()
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
			self.dispatch(location: $0)
			self.cancel()
		}) {
			self.dispatch(error: $0)
			self.cancel()
		}
	}
}

public func ==(lhs: LocationRequest, rhs: LocationRequest) -> Bool {
	return lhs.hashValue == rhs.hashValue
}
