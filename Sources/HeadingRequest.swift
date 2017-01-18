//
//  HeadingRequest.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public enum HeadingCallback {
	public typealias onSuccess = ((_ heading: CLHeading) -> (Void))
	public typealias onError = ((_ error: Error) -> (Void))
	
	case onReceivedHeading(_: Context, _: onSuccess)
	case onErrorOccurred(_: Context, _: onError)
}

public class HeadingRequest: Request {
	
	/// Callback to call when request's state did change
	public var onStateChange: ((_ old: RequestState, _ new: RequestState) -> (Void))?
	
	/// Registered callbacks
	private var registeredCallbacks: [HeadingCallback] = []
	
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
	
	/// The minimum angular change (measured in degrees) required to generate new heading events.
	/// If nil you will receive any new measured change without any filter.
	public var filter: CLLocationDegrees? {
		didSet {
			Location.updateHeadingServices()
		}
	}
	
	/// Cancel request if an error occours. By default is `false`.
	public var cancelOnError: Bool = false
	
	/// Previous measured heading
	private var previousHeading: CLHeading? = nil
	
	/// `true` if request is on location queue
	internal var isInQueue: Bool {
		return Location.isQueued(self) == true
	}
	
	/// Initialize a new heading request
	///
	/// - Parameters:
	///   - filter: The minimum angular change (measured in degrees) required to generate new heading events.
	///   - success: handler called to receive new heading measures
	///   - failure: handler called to receive errors
	public init(filter: CLLocationDegrees? = nil,
	            success: @escaping HeadingCallback.onSuccess, failure: @escaping HeadingCallback.onError) throws {
		guard CLLocationManager.headingAvailable() else {
			throw LocationError.serviceNotAvailable
		}
		self.filter = filter
		self.add(callback: HeadingCallback.onReceivedHeading(.main, success))
		self.add(callback: HeadingCallback.onErrorOccurred(.main, failure))
	}

	public func add(callback: HeadingCallback?) {
		guard let callback = callback else { return }
		self.registeredCallbacks.append(callback)
	}
	
	/// Resume a paused request or start it
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
	public func cancel() {
		Location.cancel(self)
	}
	
	public func onPause() {
		
	}
	
	public func onResume() {
		
	}
	
	public func onCancel() {
		
	}

	
	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func ==(lhs: HeadingRequest, rhs: HeadingRequest) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	/// Unique identifier of the request
	private var identifier = NSUUID().uuidString
	
	/// Hash value for Hashable protocol
	public var hashValue: Int {
		return identifier.hash
	}
	
	
	/// Dispatch error to callbacks and remove request from queue if `cancelOnError` is `true`.
	///
	/// - Parameter error: error to dispatch
	internal func dispatch(error: Error) {
		self.registeredCallbacks.forEach {
			if case .onErrorOccurred(let context, let handler) = $0 {
				context.queue.async { handler(error) }
			}
		}
		
		if self.cancelOnError == true { // remove from main location queue
			self.cancel()
			self._state = .failed
		}
	}
	
	
	/// Dispatch new heading to callbacks
	///
	/// - Parameter heading: heading
	internal func dispatch(heading: CLHeading) {
		defer {
			self.previousHeading = heading
		}
		guard self.filterIsChangedEnough(heading: heading) else { return }
		self.registeredCallbacks.forEach {
			if case .onReceivedHeading(let context, let handler) = $0 {
				context.queue.async { handler(heading) }
			}
		}
	}
	
	
	/// `true` if filter is changed enough.
	///
	/// - Parameter heading: heading to check
	/// - Returns: `true` if new heading can be dispatched to registered callbacks
	private func filterIsChangedEnough(heading: CLHeading) -> Bool {
		guard let prevHeading = self.previousHeading, let filter = self.filter else {
			return true
		}
		return abs(abs(prevHeading.trueHeading) - abs(heading.trueHeading)) > filter
	}

}
