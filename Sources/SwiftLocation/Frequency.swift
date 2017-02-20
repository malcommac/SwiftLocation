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

// MARK: - Extension to CLActivityType

extension CLActivityType: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .automotiveNavigation:	return "Automotive Navigation"
		case .fitness:				return "Fitness"
		case .other:				return "Other"
		case .otherNavigation:		return "Navigation"
		}
	}
}

/// Frequency of location updates
/// Note: `frequency` parameter is ignored (and set on `oneShot`) when `accuracy` is `IPScan`.
///
/// - continuous:		(Foreground) Continous location updates
/// - oneShot:			(Foreground) One shot location update delivery (then cancel the request)
/// - deferredUntil:	(Foreground/Background) Defeer location updates until given criteria are meet.
///						To specify an unlimited distance, pass the `CLLocationDistanceMax` constant.
///						To specify an unlimited amount of time, pass the `CLTimeIntervalMax` constant.
///						On iOS 10 it seems does not work.
/// - significant:		(Foreground/Background) Continous significant location update delivery
public enum Frequency: Equatable, Comparable, CustomStringConvertible {
	case continuous
	case oneShot
	case deferredUntil(distance: Double, timeout: TimeInterval, navigation: Bool)
	case significant
	
	public var description: String {
		switch self {
		case .continuous:
			return "Continuous"
		case .oneShot:
			return "One Shot"
		case .deferredUntil(let m, let t, let n):
			return "Deferred until (\(m) meters or \(t) seconds " + (n == true ? "navigation" : "best") + ")"
		case .significant:
			return "Significant"
		}
	}
	
	internal var isDeferredFrequency: Bool {
		switch self {
		case .deferredUntil(_,_,_):
			return true
		default:
			return false
		}
	}
}

public func == (lhs: Frequency, rhs: Frequency) -> Bool {
	switch (lhs,rhs) {
	case (.deferredUntil(let d1), .deferredUntil(let d2)) where d1 == d2:
		return true
	case (.continuous,.continuous), (.oneShot, .oneShot), (.significant, .significant):
		return true
	default:
		return false
	}
}

public func <(lhs: Frequency, rhs: Frequency) -> Bool {
	switch (lhs, rhs) {
	case (.continuous, _), (.oneShot, _):
		return true
	case (.deferredUntil(let d1,_,_), .deferredUntil(let d2,_,_)):
		return d1 < d2
	case (.significant, .significant):
		return true
	default:
		return false
	}
}

public func <=(lhs: Frequency, rhs: Frequency) -> Bool {
	if lhs == rhs { return true }
	return lhs < rhs
}

public func >(lhs: Frequency, rhs: Frequency) -> Bool {
	switch (lhs, rhs) {
	case (.significant, _):
		return true
	case (.deferredUntil(let d1,_,_), .deferredUntil(let d2,_,_)):
		return d1 > d2
	default:
		return false
	}
}

public func >=(lhs: Frequency, rhs: Frequency) -> Bool {
	if lhs == rhs { return true }
	return lhs > rhs
}
