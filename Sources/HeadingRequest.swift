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

public class HeadingRequest: Request {
	
	/// Callback to call when request's state did change
	public var onStateChange: ((_ old: RequestState, _ new: RequestState) -> (Void))?
	
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
	
	/// `true` if request is on location queue
	internal var isInQueue: Bool {
		return Location.isQueued(self) == true
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
	
	public var hashValue: Int {
		return identifier.hash
	}
	
}
