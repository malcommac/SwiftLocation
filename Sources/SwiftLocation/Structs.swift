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
import CoreLocation
import MapKit

public struct TrackerSettings: CustomStringConvertible, Equatable {
	/// Accuracy set
	var accuracy: Accuracy
	
	/// Frequency set
	var frequency: Frequency
	
	/// The type of user activity associated with the location updates.
	/// The location manager uses the information in this property as a cue to determine when location
	/// updates may be automatically paused
	var activity: CLActivityType
	
	/// Distance filter
	/// The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
	var distanceFilter: CLLocationDistance
	
	/// Description of the settings
	public var description: String {
		var desc = "\n\t- Accuracy: '\(accuracy)'"
		desc += "\n\t - Frequency: '\(frequency)'"
		desc += "\n\t - Activity: '\(activity)'"
		desc += "\n\t - Distance filter: '\(distanceFilter)'"
		return desc
	}
	
	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func ==(lhs: TrackerSettings, rhs: TrackerSettings) -> Bool {
		return (lhs.accuracy.orderValue == rhs.accuracy.orderValue && lhs.frequency == rhs.frequency && lhs.activity == rhs.activity)
	}
}

public struct LastLocation {
	/// This is the best accurated measured location (may be old, check the `timestamp`)
	private(set) var bestAccurated: CLLocation?
	/// This represent the last measured location by timestamp (may be innacurate, check `accuracy`)
	private(set) var last: CLLocation?
	
	/// Store last value
	///
	/// - Parameter location: location to set
	mutating internal func set(location: CLLocation) {
		if bestAccurated == nil {
			self.bestAccurated = location
		} else if location.horizontalAccuracy > self.bestAccurated!.horizontalAccuracy {
			self.bestAccurated = location
		}
		if last == nil {
			self.last = location
		} else if location.timestamp > self.last!.timestamp {
			self.last = location
		}
	}
}

extension CLAuthorizationStatus: CustomStringConvertible {

	/// Description of the authorization status
	public var description: String {
		switch self {
		case .authorizedAlways:		return "Authorized Always"
		case .authorizedWhenInUse:	return "Authorized When In Use"
		case .denied:				return "Denied"
		case .notDetermined:		return "Not Determined"
		case .restricted:			return "Restricted"
		}
	}
	
}
