/*
* SwiftLocation
* Easy and Efficent Location Tracker for Swift
*
* Created by:	Daniele Margutti
* Email:		hello@danielemargutti.com
* Web:			http://www.danielemargutti.com
* Twitter:		@danielemargutti
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/


import Foundation
import MapKit
import CoreLocation


/// Define the accuracy of request
///
/// - IPScan: Use geolocation via IP address scan. It very efficent and does not require user authorization, however accuracy is very low (city based at the best)
/// - any: Lowest accuracy (< 1000km is accepted)
/// - country: Lower accuracy (< 100km is accepted)
/// - city: City accuracy (<= 3km is accepted)
/// - neighborhood: Neighborhood accuracy (less than a kilometer is accepted)
/// - block: Block accuracy (hundred meters are accepted)
/// - house: House accuracy (nearest ten meters are accepted)
/// - room: Best accuracy
/// - navigation: Best accuracy specific for navigation purposes
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
	public var level: CLLocationDistance {
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
	
	/// Validation level in meters
	public var threshold: Double {
		switch self {
		case .IPScan(_):	return Double.infinity
		case .any:			return 1000000.0
		case .country:		return 100000.0
		case .city:			return 5000.0
		case .neighborhood:	return 1000.0
		case .block:		return 100.0
		case .house:		return 15.0
		case .room:			return 5.0
		case .navigation:	return 5.0
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
			return (location.horizontalAccuracy <= self.threshold)
		}
	}
	
	
	/// CoreLocation user authorizations are required for this accuracy
	public var requestUserAuth: Bool {
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
		case .neighborhood:				return "Neighborhood (\(self.threshold) meters)"
		case .block:					return "Block (\(self.threshold) meters)"
		case .house:					return "House (\(self.threshold) meters)"
		case .room:						return "Room"
		case .navigation:				return "Navigation"
		}
	}
}
