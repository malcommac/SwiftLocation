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
///
/// - continuous: continous location updates
/// - oneShot: one shot location update delivery (then cancel the request)
/// - whenTravelled: continous location update when travelled distance is made or timeout reached (application must support background location)
/// - significant: continous significant location update delivery
public enum Frequency: Equatable, Comparable, CustomStringConvertible {
	case continuous
	case oneShot
	case whenTravelled(meters: Double, timeout: TimeInterval)
	case backgroundUpdate(meters: Double, timeout: TimeInterval)
	case significant
	
	public var description: String {
		switch self {
		case .continuous:								return "Continuous"
		case .oneShot:									return "One Shot"
		case .whenTravelled(let m, let t):				return "Travelled (\(m) meters or \(t) seconds)"
		case .backgroundUpdate(let m, timeout: let t):	return "Background (\(m) meters or \(t) seconds)"
		case .significant:								return "Significant"
		}
	}
	
	internal var isTravelledFrequency: Bool {
		switch self {
		case .whenTravelled(_,_):
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
	case (.whenTravelled(let d1), .whenTravelled(let d2)):
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
	case (.whenTravelled(let d1), .whenTravelled(let d2)):
		return d1 > d2
	default:
		return false
	}
}

public func >=(lhs: Frequency, rhs: Frequency) -> Bool {
	if lhs == rhs { return true }
	return lhs > rhs
}
