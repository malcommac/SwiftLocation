//
//  RegionRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public enum RegionCallback {
	public typealias onEvent = ((Void) -> (Void))
	public typealias onFailure = ((Error) -> (Void))
	
	case onEnter(_: Context, _: onEvent)
	case onExit(_: Context, _: onEvent)
	case onError(_: Context, _: onFailure)
	
	internal var isEnterEvent: Bool {
		switch self {
		case .onEnter(_, _):	return true
		default:				return false
		}
	}
	
	internal var isExitEvent: Bool {
		switch self {
		case .onExit(_, _):	return true
		default:				return false
		}
	}
}

public enum RegionEvent {
	case entered
	case exited
}

public class RegionRequest: Request {
	
	/// Callback to call when request's state did change
	public var onStateChange: ((_ old: RequestState, _ new: RequestState) -> (Void))?
	
	/// Registered callbacks
	private var registeredCallbacks: [RegionCallback] = []
	
	/// Callback called when monitoring for this region starts
	public var onStartMonitoring: ((Void) -> (Void))? = nil
	
	public typealias DetermineStateCallback = ((CLRegionState) -> (Void))
	private var stateCallback: DetermineStateCallback? = nil
	
	/// Region to monitor
	private(set) var region: CLCircularRegion
	
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
	
	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func ==(lhs: RegionRequest, rhs: RegionRequest) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}

	/// Unique identifier of the request
	private var identifier = NSUUID().uuidString
	
	public var cancelOnError: Bool = false
	
	/// Hash value for Hashable protocol
	public var hashValue: Int {
		return identifier.hash
	}
	
	public init(center: CLLocationCoordinate2D, radius: CLLocationDistance,
	            onEnter enter: RegionCallback.onEvent?, onExit exit: RegionCallback.onEvent?, error: RegionCallback.onFailure?) throws {
		guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
			throw LocationError.serviceNotAvailable
		}
		
		self.region = CLCircularRegion(center: center, radius: radius, identifier: self.identifier)
		if enter != nil { self.add(callback: .onEnter(.main, enter!)) }
		if exit != nil { self.add(callback: .onExit(.main, exit!)) }
		if error != nil { self.add(callback: .onError(.main, error!)) }
	}
	
	private func add(callback: RegionCallback?) {
		guard let callback = callback else { return }
		registeredCallbacks.append(callback)
		self.updateNotifications()
	}
	
	/// `true` if request is on location queue
	internal var isInQueue: Bool {
		return Location.isQueued(self) == true
	}
	
	public func determineState(_ callback: @escaping DetermineStateCallback) -> Bool {
		guard self.isInQueue, self.state.isRunning else {
			return false
		}
		self.stateCallback = callback
		Location.locationManager.requestState(for: self.region)
		return true
	}
	
	private func updateNotifications() {
		var hasOnEnterNotify = false
		var hasOnExitNotify = false
		for callback in registeredCallbacks {
			if case .onEnter(_,_) = callback { hasOnEnterNotify = true }
			if case .onExit(_,_) = callback { hasOnExitNotify = true }
		}
		
		region.notifyOnEntry = hasOnEnterNotify
		region.notifyOnExit = hasOnExitNotify
	}
	
	public func resume() {
		Location.start(self)
	}
	
	public func pause() {
		Location.pause(self)
	}
	
	public func cancel() {
		Location.cancel(self)
	}
	
	public func onResume() {
		
	}
	
	public func onCancel() {
		
	}
	
	public func onPause() {
		
	}
	
	internal func dispatch(error: Error) {
		self.registeredCallbacks.forEach {
			if case .onError(let context, let handler) = $0 {
				context.queue.async { handler(error) }
			}
		}
		
		if self.cancelOnError == true { // remove from main location queue
			self.cancel()
			self._state = .failed
		}
	}
	
	internal func dispatch(event: RegionEvent) {
		self.registeredCallbacks.forEach {
			switch ($0, event) {
			case (.onEnter(let context, let handler), .entered) :
				context.queue.async { handler() }
			case (.onExit(let context, let handler), .exited):
				context.queue.async { handler() }
			default:
				break
			}
		}
	}
	
	internal func dispatch(state: CLRegionState) {
		stateCallback?(state)
	}
	
}
