//
//  UpdateFrequency.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public typealias LocationHandlerError = (LocationError -> Void)
public typealias LocationHandlerSuccess = (CLLocation -> Void)

public typealias RLocationErrorHandler = (LocationError -> Void)
public typealias RLocationSuccessHandler = (CLPlacemark -> Void)

public typealias HeadingHandlerError = (LocationError -> Void)
public typealias HeadingHandlerSuccess = (CLHeading -> Void)

public typealias RegionHandlerStateDidChange = (Void -> Void)
public typealias RegionHandlerError = (LocationError -> Void)

public typealias VisitHandler = (CLVisit -> Void)
public typealias DidRangeBeaconsHandler = ([CLBeacon] -> Void)
public typealias RangeBeaconsDidFailHandler = (LocationError -> Void)

public enum ReverseService {
	case Apple
	case Google
}

internal struct CLPlacemarkDictionaryKey {
	// Parse address data
	static let kSubAdministrativeArea = "SubAdministrativeArea"
	static let kSubLocality           = "SubLocality"
	static let kState                 = "State"
	static let kStreet                = "Street"
	static let kThoroughfare          = "Thoroughfare"
	static let kFormattedAddressLines = "FormattedAddressLines"
	static let kSubThoroughfare       = "SubThoroughfare"
	static let kPostCodeExtension     = "PostCodeExtension"
	static let kCity                  = "City"
	static let kZIP                   = "ZIP"
	static let kCountry               = "Country"
	static let kCountryCode           = "CountryCode"
}

protocol LocationManagerRequest	{
	var UUID: String { get }
}

public enum LocationError: ErrorType, CustomStringConvertible {
	case MissingAuthorizationInPlist
	case RequestTimeout
	case AuthorizationDidChange(newStatus: CLAuthorizationStatus)
	case LocationManager(error: NSError?)
	case LocationNotAvailable
	case NoDataReturned
	case NotSupported
	
	public var description: String {
		switch self {
		case .MissingAuthorizationInPlist:
			return "Missing Authorization in .plist file"
		case .RequestTimeout:
			return "Timeout for request"
		case .AuthorizationDidChange:
			return "Authorization did change"
		case .LocationManager(let err):
			if let error = err {
				return "Location manager error: \(error.localizedDescription)"
			} else {
				return "Generic location manager error"
			}
		case .LocationNotAvailable:
			return "Location not avaiable"
		case .NoDataReturned:
			return "No Data Returned"
		case .NotSupported:
			return "Feature Not Supported"
		}
	}
}

public enum LocationServiceState: Equatable {
	case Disabled
	case Undetermined
	case Denied
	case Restricted
	case Authorized(always: Bool)
}

public func == (lhs: LocationServiceState, rhs: LocationServiceState) -> Bool {
	switch (lhs,rhs) {
	case (.Authorized(let a1), .Authorized(let a2)):
		return a1 == a2
	case (.Disabled,.Disabled), (.Undetermined,.Undetermined), (.Denied,.Denied), (.Restricted,.Restricted):
		return true
	default:
		return false
	}
}

public enum LocationAuthType {
	case None
	case Always
	case OnlyInUse
}

extension CLLocationManager {
	
	public static var locationAuthStatus: LocationServiceState {
		get {
			if CLLocationManager.locationServicesEnabled() == false {
				return .Disabled
			} else {
				let status = CLLocationManager.authorizationStatus()
				switch status {
				case .NotDetermined:
					return .Undetermined
				case .Denied:
					return .Denied
				case .Restricted:
					return .Restricted
				case .AuthorizedAlways:
					return .Authorized(always: true)
				case .AuthorizedWhenInUse:
					return .Authorized(always: false)
				}
			}
		}
	}
	
	public static var bundleLocationAuthType: LocationAuthType {
		let hasAlwaysAuth = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") != nil)
		let hasInUseAuth = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription") != nil)
		
		if hasAlwaysAuth == true {
			return .Always
		}
		
		if hasInUseAuth == true {
			return .OnlyInUse
		}
		return .None
	}
}

public enum Accuracy: Int {
	case Any = 0
	case Country = 1
	case City = 2
	case Neighborhood = 3
	case Block = 4
	case House = 5
	case Room = 6
	case Navigation = 7
	
	public var meters: Double {
		switch self {
		case Any:			return Double.infinity
		case Country:		return 50000.0
		case City:			return kCLLocationAccuracyThreeKilometers
		case Neighborhood:	return kCLLocationAccuracyKilometer
		case Block:			return kCLLocationAccuracyHundredMeters
		case House:			return kCLLocationAccuracyNearestTenMeters
		case Room:			return kCLLocationAccuracyBest
		case Navigation:	return kCLLocationAccuracyBestForNavigation
		}
	}
	
	public func isLocationValidForAccuracy(obj: CLLocation) -> Bool {
		let hAccuracy = obj.horizontalAccuracy
		return (hAccuracy <= self.meters)
	}
}

public enum UpdateFrequency: Equatable, Comparable {
	case Continuous
	case OneShot
	case ByDistanceIntervals(meters: Double)
	case Significant
}

public func == (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	switch (lhs,rhs) {
	case (.ByDistanceIntervals(let d1), .ByDistanceIntervals(let d2)) where d1 == d2:
		return true
	case (.Continuous,.Continuous), (.OneShot, .OneShot), (.Significant, .Significant):
		return true
	default:
		return false
	}
}

public func < (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	return u_lowerThan(includeEqual: false, lhs: lhs, rhs: rhs)
}

public func <= (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	return u_lowerThan(includeEqual: true, lhs: lhs, rhs: rhs)
}

public func > (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	return u_graterThan(includeEqual: false, lhs: lhs, rhs: rhs)
}

public func >= (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	return u_graterThan(includeEqual: true, lhs: lhs, rhs: rhs)
}


private func u_lowerThan(includeEqual e: Bool, lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	switch (lhs, rhs) {
	case (.Continuous, _), (.OneShot, _):
		return true
	case (.ByDistanceIntervals(let d1),.ByDistanceIntervals(let d2)):
		return (e == true ? d1 <= d2 : d1 < d2)
	case (.Significant, .Significant):
		return true
	default:
		return false
	}
}

private func u_graterThan(includeEqual e: Bool, lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	switch (lhs, rhs) {
	case (.Significant, _):
		return true
	case (.ByDistanceIntervals(let d1),.ByDistanceIntervals(let d2)):
		return (e == true ? d1 >= d2 : d1 > d2)
	default:
		return false
	}
}