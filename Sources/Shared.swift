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
	case backgroundModeNotSet
}

public enum Usage {
	case always
	case inuse
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
	
	public static var locationUsage: Usage {
		let app = Bundle.main
		if let _ = app.object(forInfoDictionaryKey: Usage.always.rawValue) {
			return Usage.always
		}
		if let _ = app.object(forInfoDictionaryKey: Usage.inuse.rawValue) {
			return Usage.inuse
		}
		return Usage.none
	}
	
	public static var isBackgroundUpdateEnabled: Bool {
		if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? NSArray {
			if backgroundModes.contains("location") && backgroundModes.contains("fetch") {
				return true
			}
		}
		return false
	}

	
	public func requireAuthIfNeeded() throws -> Bool {
		if LocAuth.isAuthorized == true { return false }
		switch CLLocationManager.locationUsage {
		case .always:
			self.requestAlwaysAuthorization()
		case .inuse:
			self.requestWhenInUseAuthorization()
		case .none:
			throw LocationError.missingAuthInInfoPlist
		}
		return true
	}
}
