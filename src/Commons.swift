//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2016 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreLocation
import MapKit

extension CLGeocoder: Request {
	
	public func cancel() {
		cancelGeocode()
	}
	
	public func pause() {
		// not available
	}
	
	public func start() {
		// not available
	}
	
	public var UUID: String {
		return "\(self.hash)"
	}
}

extension NSURLSessionDataTask: Request {

	public func pause() {
		self.suspend()
	}
	
	public func start() {
		self.resume()
	}
	
	public var UUID: String {
		return "\(self.hash)"
	}
}

public protocol Request {
	func cancel()
	func pause()
	func start()
	
	var UUID: String { get }
}

/// Handlers

public typealias LocationHandlerError = ((CLLocation?, LocationError) -> Void)
public typealias LocationHandlerSuccess = (CLLocation -> Void)
public typealias LocationHandlerPaused = (CLLocation? -> Void)

public typealias RLocationErrorHandler = (LocationError -> Void)
public typealias RLocationSuccessHandler = (CLPlacemark -> Void)

public typealias HeadingHandlerError = (LocationError -> Void)
public typealias HeadingHandlerSuccess = (CLHeading -> Void)
public typealias HeadingHandlerCalibration = (Void -> Bool)

public typealias RegionHandlerStateDidChange = (Void -> Void)
public typealias RegionHandlerError = (LocationError -> Void)

public typealias VisitHandler = (CLVisit -> Void)
public typealias DidRangeBeaconsHandler = ([CLBeacon] -> Void)
public typealias RangeBeaconsDidFailHandler = (LocationError -> Void)

/**
Type of service to used to perform the request

- Apple:  standard apple services
- Google: google own services (maybe limited in quota usage)
*/
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

// MARK: - Location Errors

/**
Define all possible error related to SwiftLocation library

- MissingAuthorizationInPlist: Missing authorization in plist file (NSLocationAlwaysUsageDescription,NSLocationWhenInUseUsageDescription)
- RequestTimeout:              Request has timed out
- AuthorizationDidChange:      Authorization status of the location manager did change due to user's interaction
- LocationManager:             Location manager's error
- LocationNotAvailable:        Requested location is not available
- NoDataReturned:              No data returned from this request
- NotSupported:                Feature is not supported by the current hardware
*/
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

/**
Location service state

- Undetermined: No authorization status could be determined.
- Denied:       The user explicitly denied access to location data for this app.
- Restricted:   This app is not authorized to use location services. The user cannot change this app’s status, possibly due to active restrictions such as parental controls being in place.
- Authorized:   This app is authorized to use location services.
*/
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

/**
Location authorization status

- None:      no authorization was provided
- Always:    app can receive location updates both in background and foreground
- OnlyInUse: app can receive location updates only in foreground
*/
public enum LocationAuthType {
	case None
	case Always
	case OnlyInUse
}

// MARK: - CLLocationManager

extension CLLocationManager {
	
		/// This var return the current status of the location manager authorization session
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
	
		/// This var return the current status of the application's configuration
		/// Since iOS8 you must specify a key which define the usage type of the location manager; you can use
		/// NSLocationAlwaysUsageDescription if your app can uses location manager both in background and foreground or
		/// NSLocationWhenInUseUsageDescription if your app is limited to foreground location update only.
		/// Value of these keys if the message you want to show into system location request message the first time you
		/// will access to the location manager.
	internal static var bundleLocationAuthType: LocationAuthType {
		let hasAlwaysAuth = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") != nil)
		let hasInUseAuth = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription") != nil)
		
		if hasAlwaysAuth == true { return .Always }
		if hasInUseAuth == true { return .OnlyInUse }
		return .None
	}
}

//MARK: Accuracy

/**
Allows you to specify the accuracy you want to achieve with a request.

- IPScan:                                                Current location is discovered via IP Scan. This require a valid internet connection
														 and don't use device's GPS sensor. It's good to preserve device's battery but does not
														 return a precise position.
- Any:                                                   First available location is accepted, no matter the accuracy
- Country:                                               Only locations accurate to the nearest 100 kilometers are dispatched
- City:                                                  Only locations accurate to the nearest three kilometers are dispatched
- Neighborhood:                                          Only locations accurate to the nearest kilometer are dispatched
- Block:                                                 Only locations accurate to the nearest one hundred meters are dispatched
- House:                                                 Only locations accurate to the nearest ten meters are dispatched
- Room:                                                  Use the highest-level of accuracy, may use high energy
- Navigation:                                            Use the highest possible accuracy and combine it with additional sensor data.
														 Use it only for applications that require precise position information ar all times
														 (you should use it only when device is plugged in due to high battery usage level)
*/
public enum Accuracy: Int {
	case IPScan = -1
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
		case Country:		return 100000.0
		case City:			return kCLLocationAccuracyThreeKilometers
		case Neighborhood:	return kCLLocationAccuracyKilometer
		case Block:			return kCLLocationAccuracyHundredMeters
		case House:			return kCLLocationAccuracyNearestTenMeters
		case Room:			return kCLLocationAccuracyBest
		case Navigation:	return kCLLocationAccuracyBestForNavigation
		case IPScan:		return Double.infinity // Not used
		}
	}
	
	/**
	Validate a provided location against current value of the accuracy
	
	- parameter obj: provided location object
	
	- returns: true if location has an accuracy equal or grater than the one set by the struct itself
	*/
	internal func isLocationValidForAccuracy(obj: CLLocation) -> Bool {
		let hAccuracy = obj.horizontalAccuracy
		return (hAccuracy <= self.meters)
	}
}

//MARK: UpdateFrequency

/**
This enum specify the type of frequency you want to receive updates about location when subscription
is added to the main queue of the location manager.

- Continuous:          receive each new valid location, never stop (you must stop it manually).
- OneShot:             the first valid location data is received, then the request will be invalidated.
- ByDistanceIntervals: receive a new update each time a new distance interval is travelled. Useful to keep battery usage low.
- Significant:         receive only valid significant location updates. This capability provides tremendous power savings for apps that want to track a user’s approximate location and do not need highly accurate position information.
*/
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

/**
Specify an interval to receive new heading events

- Continuous:    Receive events continuously; if you specify a non-nil interval events are dispatched when a minimum interval is reached
- MagneticNorth: Receive events only when magnetic north degree is changed at least of specified interval
- TrueNorth:     Receive events only when true north degree is changed at least of specified interval
*/
public enum HeadingFrequency {
	case Continuous(interval: NSTimeInterval?)
	case MagneticNorth(minChange: CLLocationDirection)
	case TrueNorth(minChange: CLLocationDirection)
}