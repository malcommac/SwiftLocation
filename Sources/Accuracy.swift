//
//  Accuracy.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

public enum Accuracy: CustomStringConvertible {
	case IPScan(_: IPService)
	case any
	case country
	case city
	case neighborhood
	case block
	case house
	case room
	case navigation
	
	/// Order by accuracy
	internal var orderValue: Int {
	switch self {
	case .IPScan(_):	return 0
	case .any:			return 1
	case .country:		return 2
	case .city:			return 3
	case .neighborhood:	return 4
	case .block:		return 5
	case .house:		return 6
	case .room:			return 7
	case .navigation:	return 8
	}
	}
	
	/// Accuracy measured in meters
	public var meters: Double {
		switch self {
		case .IPScan(_):	return Double.infinity
		case .any:			return 1000000.0
		case .country:		return 100000.0
		case .city:			return kCLLocationAccuracyThreeKilometers
		case .neighborhood:	return kCLLocationAccuracyKilometer
		case .block:		return kCLLocationAccuracyHundredMeters
		case .house:		return kCLLocationAccuracyNearestTenMeters
		case .room:			return kCLLocationAccuracyBest
		case .navigation:	return kCLLocationAccuracyBestForNavigation
		}
	}
	
	/// Validate given `location` against the current accuracy.
	///
	/// - Parameter location: location to validate
	/// - Returns: `true` if valid, `false` otherwise
	public func isValid(_ location: CLLocation) -> Bool {
		switch self {
		case .room, .navigation:
			// This because kCLLocationAccuracyBest and kCLLocationAccuracyBestForNavigation
			// are not real values but only placeholder for a particular accuracy type
			// and values depended by the hardware.
			return (location.horizontalAccuracy < kCLLocationAccuracyNearestTenMeters)
		default:
			// Otherwise we can check meters
			return (location.horizontalAccuracy <= self.meters)
		}
	}
	
	
	/// CoreLocation user authorizations are required for this accuracy
	public var accuracyRequireAuthorization: Bool {
		get {
			guard case .IPScan(_) = self else { // only ip-scan does not require auth
				return true
			}
			return false
		}
	}
	
	/// Description of the accuracy
	public var description: String {
		switch self {
		case .IPScan(let service):		return "IPScan \(service)"
		case .any:						return "Any"
		case .country:					return "Country"
		case .city:						return "City"
		case .neighborhood:				return "Neighborhood (\(self.meters) meters)"
		case .block:					return "Block (\(self.meters) meters)"
		case .house:					return "House (\(self.meters) meters)"
		case .room:						return "Room"
		case .navigation:				return "Navigation"
		}
	}
}
