//
//  RequestPool.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 18/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

internal protocol RequestPoolProtocol {
	var requiredAuthorization: Authorization { get }
	func dispatch(error: Error)
	func dispatch(value: Any)
	func set(_ newState: RequestState, forRequestsIn states: Set<RequestState>)
}

internal class RequestsPool<T: Request> : RequestPoolProtocol, Sequence {
	private var list: Set<T> = []
	
	public var countRunning: Int {
		return list.reduce(0, { return $0 + ($1.state.isRunning ? 1 : 0) } )
	}
	
	@discardableResult
	public func add(_ item: T) -> Bool {
		guard !self.isQueued(item) else { return false }
		list.insert(item)
		return true
	}
	
	@discardableResult
	public func remove(_ item: T) -> Bool {
		guard self.isQueued(item) else { return false }
		list.remove(item)
		return true
	}
	
	public func isQueued(_ item: T) -> Bool {
		return list.contains(item)
	}
	
	public func makeIterator() -> Set<T>.Iterator {
		return list.makeIterator()
	}
	
	public func set(_ newState: RequestState, forRequestsIn states: Set<RequestState>) {
		list.forEach {
			if let request = $0 as? LocationRequest {
				if states.contains($0.state) {
					request._state = newState
				}
			}
		}
	}
	
	public func dispatch(error: Error) {
		list.forEach { $0.dispatch(error: error) }
	}
	
	public func dispatch(value: Any) {
		// Heading request
		if T.self is HeadingRequest.Type, let v = value as? CLHeading {
			list.forEach { ($0 as! HeadingRequest).dispatch(heading: v) }
		}
		// Location request
		else if T.self is LocationRequest.Type, let v = value as? CLLocation {
			list.forEach { ($0 as! LocationRequest).dispatch(location: v) }
		}
		// Region request
		else if T.self is RegionRequest.Type {
			if let v = value as? RegionEvent {
				list.forEach { ($0 as! RegionRequest).dispatch(event: v) }
			}
			else if let v = value as? CLRegionState {
				list.forEach { ($0 as! RegionRequest).dispatch(state: v) }
			}
		}
	}
	
	public func hasBackgroundRequests() -> Bool {
		for request in list {
			if request.isBackgroundRequest {
				return true
			}
		}
		return false
	}
	
	/// Return the minimum allowed authorization we should require to allow
	/// currently queued and running requests
	public var requiredAuthorization: Authorization {
		return list.reduce(.none) { $0 < $1.requiredAuth ? $0 : $1.requiredAuth }
	}
	
}
