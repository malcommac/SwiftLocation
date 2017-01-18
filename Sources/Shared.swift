//
//  Shared.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

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
		case .running, .failed, .idle:
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

/// Public Request Protocol
public protocol Request: class, Hashable, Equatable {
	
	func resume()
	func pause()
	func cancel()
	
	func onResume()
	func onPause()
	func onCancel()
	
	var state: RequestState { get }
	
	var requiredAuth: Authorization { get }
	
	var isBackgroundRequest: Bool { get }
	
	func dispatch(error: Error)
}

/// Location errors
///
/// - missingAuthInInfoPlist: missing authorization strings (`NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` in Info.plist)
/// - authDidChange: authorization is changed to `.denied` or `.restricted` mode. Location services are not available anymore.
/// - timeout: timeout for request is reached
/// - serviceNotAvailable: hardware does not support required service
/// - backgroundModeNotSet: one or more requests needs background capabilities enabled (see `UIBackgroundModes` in Info.plist)
public enum LocationError: Error {
	case missingAuthInInfoPlist
	case authDidChange(_: CLAuthorizationStatus)
	case timeout
	case serviceNotAvailable
	case requireAlwaysAuth
	case authorizationDenided
	case backgroundModeNotSet
	case noData
	case invalidData
	case other(_: String)
}

public enum Authorization : CustomStringConvertible, Comparable, Equatable {
	case always
	case inuse
	case both
	case none
	
	public var rawValue: String {
		switch self {
		case .always:
			return "NSLocationAlwaysUsageDescription"
		case .inuse:
			return "NSLocationWhenInUseUsageDescription"
		default:
			return ""
		}
	}
	
	private var order: Int {
		switch self {
		case .both:		return 0
		case .always:	return 1
		case .inuse:	return 2
		case .none:		return 3
		}
	}
	
	public var description: String {
		switch self {
		case .both:		return "Both"
		case .always:	return "Always"
		case .inuse:	return "When In Use"
		case .none:		return "None"
		}
	}
	
	public static func <(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order < rhs.order
	}
	
	public static func <=(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order <= rhs.order
	}
	
	public static func >(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order > rhs.order
	}
	
	public static func >=(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order >= rhs.order
	}
	
	public static func ==(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order == rhs.order
	}
}

public enum LocAuth {
	case disabled
	case undetermined
	case denied
	case restricted
	case alwaysAuthorized
	case inUseAuthorized
	
	public static var status: LocAuth {
		guard CLLocationManager.locationServicesEnabled() else {
			return .disabled
		}
		switch CLLocationManager.authorizationStatus() {
		case .notDetermined:		return .undetermined
		case .denied:				return .denied
		case .restricted:			return .restricted
		case .authorizedAlways:		return .alwaysAuthorized
		case .authorizedWhenInUse:	return .inUseAuthorized
		}
	}
	
	public static var isAuthorized: Bool {
		switch LocAuth.status {
		case .alwaysAuthorized, .inUseAuthorized:
			return true
		default:
			return false
		}
	}
}

public extension CLLocationManager {
	
	public static var appAuthorization: Authorization {
		let app = Bundle.main
		var isAlways = false
		var isWhenInUse = false
		if let _ = app.object(forInfoDictionaryKey: Authorization.always.rawValue) {
			isAlways = true
		}
		if let _ = app.object(forInfoDictionaryKey: Authorization.inuse.rawValue) {
			isWhenInUse = true
		}
		
		if isWhenInUse && isAlways {
			return .both
		} else {
			if isWhenInUse { return .inuse }
			else if isAlways { return .always }
			return .none
		}
	}
	
	public static var isBackgroundUpdateEnabled: Bool {
		if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? NSArray {
			if backgroundModes.contains("location") && backgroundModes.contains("fetch") {
				return true
			}
		}
		return false
	}

}
