//
//  UpdateFrequency.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

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
/// - whenTravelled:	(Foreground/Background) Continous location update when travelled distance is made or timeout reached.
///						To specify an unlimited distance, pass the `CLLocationDistanceMax` constant.
///						To specify an unlimited amount of time, pass the `CLTimeIntervalMax` constant.
/// - significant:		(Foreground/Background) Continous significant location update delivery
public enum Frequency: Equatable, Comparable, CustomStringConvertible {
	case continuous
	case oneShot
	case whenTravelled(distance: Double, timeout: TimeInterval, navigation: Bool)
	case significant
	
	public var description: String {
		switch self {
		case .continuous:
			return "Continuous"
		case .oneShot:
			return "One Shot"
		case .whenTravelled(let m, let t, let n):
			return "Travelled (\(m) meters or \(t) seconds " + (n == true ? "navigation" : "best") + ")"
		case .significant:
			return "Significant"
		}
	}
	
	internal var isDeferredFrequency: Bool {
		switch self {
		case .whenTravelled(_,_,_):
			return true
		default:
			return false
		}
	}
}

public func == (lhs: Frequency, rhs: Frequency) -> Bool {
	switch (lhs,rhs) {
	case (.whenTravelled(let d1), .whenTravelled(let d2)) where d1 == d2:
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
	case (.whenTravelled(let d1,_,_), .whenTravelled(let d2,_,_)):
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
	case (.whenTravelled(let d1,_,_), .whenTravelled(let d2,_,_)):
		return d1 > d2
	default:
		return false
	}
}

public func >=(lhs: Frequency, rhs: Frequency) -> Bool {
	if lhs == rhs { return true }
	return lhs > rhs
}
