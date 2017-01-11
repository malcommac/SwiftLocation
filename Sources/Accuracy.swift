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

public enum Accuracy: Int, CustomStringConvertible {
	case IPScan			= -1
	case any			= 0
	case country		= 1
	case city			= 2
	case neighborhood	= 3
	case block			= 4
	case house			= 5
	case room			= 6
	case navigation		= 7
	
	
	/// Accuracy measured in meters
	public var meters: Double {
		switch self {
		case .IPScan:		return Double.infinity
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
	
	
	/// Description of the accuracy
	public var description: String {
		switch self {
		case .IPScan:		return "IPScan"
		case .any:			return "Any"
		case .country:		return "Country"
		case .city:			return "City"
		case .neighborhood:	return "Neighborhood (\(self.meters) meters)"
		case .block:		return "Block (\(self.meters) meters)"
		case .house:		return "House (\(self.meters) meters)"
		case .room:			return "Room"
		case .navigation:	return "Navigation"
		}
	}
}
