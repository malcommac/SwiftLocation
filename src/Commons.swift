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

/**
State of the beacon region monitoring

- Entered: entered into the region
- Exited:  exited from the region
*/
public enum RegionState {
	case entered
	case exited
}

/**
*  This option set define the type of events you can monitor via BeaconManager class's monitor() func
*/
public struct Event : OptionSet {
	public let rawValue: UInt8
	public init(rawValue: UInt8) { self.rawValue = rawValue }
	
	/// Monitor a region cross boundary event (enter and exit from the region)
	public static let RegionBoundary = Event(rawValue: 1 << 0)
	/// Monitor beacon ranging
	public static let Ranging = Event(rawValue: 1 << 1)
	/// Monitor both region cross boundary and beacon ranging events
	public static let All : Event = [RegionBoundary, Ranging]
}


/**
*  This structure define a beacon object
*/
public struct Beacon {
	public var proximityUUID: String
	public var major: CLBeaconMajorValue?
	public var minor: CLBeaconMinorValue?
	
	/**
	Initializa a new beacon to monitor
	
	- parameter proximity: This property contains the identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool
	- parameter major:     The major property contains a value that can be used to group related sets of beacons. For example, a department store might assign the same major value for all of the beacons on the same floor.
	- parameter minor:     The minor property specifies the individual beacon within a group. For example, for a group of beacons on the same floor of a department store, this value might be assigned to a beacon in a particular section.
	
	- returns: a new beacon structure
	*/
	public init(proximity: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?) {
		self.proximityUUID = proximity
		self.major = major
		self.minor = minor
	}
}

/**
This define the state of a request. Usually you don't need to acces to this info

- Pending:         A request is pending when it's never started
- Paused:          A request is paused when it's on queue but it will not receive any events
- Cancelled:       A cancelled request cannot be queued again
- Running:         A request is running when it's on queue and will receive events
- WaitingUserAuth: In this state the request is paused and the system is waiting for user authorization
- Undetermined:    Undetermined state is usually used when the object cannot support request protocol
*/
public enum RequestState {
	case pending
	case paused
	case cancelled(error: LocationError?)
	case running
	case waitingUserAuth
	case undetermined
	
	/// Request is running
	public var isRunning: Bool {
		switch self {
		case .running:
			return true
		default:
			return false
		}
	}
	
	/// Request is not running but can be started anytime
	public var canStart: Bool {
		switch self {
		case .paused, .pending:
			return true
		default:
			return false
		}
	}
	
	/// Request is on queue but it's in pause state
	public var isPending: Bool {
		switch self {
		case .pending, .waitingUserAuth:
			return true
		default:
			return false
		}
	}
	
	/// Request is on queue but it's in pause state
	public var isCancelled: Bool {
		switch self {
		case .cancelled(_):
			return true
		default:
			return false
		}
	}
}

// MARK: - Support for Request protocol in CLGeocoder object

extension CLGeocoder: Request {
	
	public func cancel(_ error: LocationError?) {
		cancelGeocode()
	}
	
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
	
	public var rState: RequestState {
		return .undetermined
	}
	
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange? {
		// not supported
		get { return nil }
		set { }
	}
}

// MARK: - Support for Request protocol in NSURLSessionDataTast object

extension URLSessionDataTask: Request {

	public func pause() {
		self.suspend()
	}
	
	public func start() {
		self.resume()
	}
	
	public var UUID: String {
		return "\(self.hash)"
	}
	
	public func cancel(_ error: LocationError?) {
		self.cancel()
	}
	
	public var rState: RequestState {
		return .undetermined
	}
	
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange? {
		// not supported
		get { return nil }
		set { }
	}
}

/**
*  Each request in SwiftLocation support this protocol
*/
public protocol Request {
	/**
	Cancel a running active request. Remove it from queue and mark it as cancelled.
	
	- parameter error: optional error to cancel the request
	*/
	func cancel(_ error: LocationError?)
	
	/**
	Cancel a running request without passing an error
	*/
	func cancel()
	
	/**
	Pause a running request
	*/
	func pause()
	
	/**
	Start a request by adding it to the relative queue
	*/
	func start()
	
	/// Unique identifier of the request
	var UUID: String { get }
	
	/// State of the request
	var rState: RequestState { get }
	
	//  You can observe for authorization changes in CLLocationManager
	var onAuthorizationDidChange: LocationHandlerAuthDidChange? { get set }
}

/// Handlers

public typealias LocationHandlerError = ((CLLocation?, LocationError) -> Void)
public typealias LocationHandlerSuccess = ((CLLocation) -> Void)
public typealias LocationHandlerPaused = ((CLLocation?) -> Void)

public typealias LocationHandlerAuthDidChange = ((CLAuthorizationStatus?) -> Void)

public typealias RLocationErrorHandler = ((LocationError) -> Void)
public typealias RLocationSuccessHandler = ((CLPlacemark) -> Void)

public typealias HeadingHandlerError = ((LocationError) -> Void)
public typealias HeadingHandlerSuccess = ((CLHeading) -> Void)
public typealias HeadingHandlerCalibration = ((Void) -> Bool)

public typealias VisitHandler = ((CLVisit) -> Void)

public typealias RegionStateDidChange = ((RegionState) -> Void)
public typealias RegionBeaconsRanging = (([CLBeacon]) -> Void)
public typealias RegionMonitorError = ((LocationError) -> Void)

/**
Type of service to used to perform the request

- Apple:  standard apple services
- Google: google own services (maybe limited in quota usage)
*/
public enum ReverseService {
	case apple
	case google
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

// MARK: - CLAuthorizationStatus description implementation
extension CLAuthorizationStatus: CustomStringConvertible {
	public var description: String {
		switch self {
		case .denied:
			return "User Denied"
		case .authorizedAlways:
			return "Always Authorized"
		case .notDetermined:
			return "Not Determined"
		case .restricted:
			return "Restricted"
		case .authorizedWhenInUse:
			return "Authorized In Use"
		}
	}
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
public enum LocationError: Error, CustomStringConvertible {
	case missingAuthorizationInPlist
	case requestTimeout
	case authorizationDidChange(newStatus: CLAuthorizationStatus)
	case locationManager(error: NSError?)
	case locationNotAvailable
	case noDataReturned
	case notSupported
	case invalidBeaconData
	
	public var description: String {
		switch self {
		case .missingAuthorizationInPlist:
			return "Missing Authorization in .plist file"
		case .requestTimeout:
			return "Timeout for request"
		case .authorizationDidChange(let status):
			return "Failed due to user auth status: '\(status)'"
		case .locationManager(let err):
			if let error = err {
				return "Location manager error: \(error.localizedDescription)"
			} else {
				return "Generic location manager error"
			}
		case .locationNotAvailable:
			return "Location not avaiable"
		case .noDataReturned:
			return "No Data Returned"
		case .notSupported:
			return "Feature Not Supported"
		case .invalidBeaconData:
			return "Cannot create monitor for beacon. Invalid data"
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
	case disabled
	case undetermined
	case denied
	case restricted
	case authorized(always: Bool)
}

public func == (lhs: LocationServiceState, rhs: LocationServiceState) -> Bool {
	switch (lhs,rhs) {
	case (.authorized(let a1), .authorized(let a2)):
		return a1 == a2
	case (.disabled,.disabled), (.undetermined,.undetermined), (.denied,.denied), (.restricted,.restricted):
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
	case none
	case always
	case onlyInUse
}

// MARK: - CLLocationManager

extension CLLocationManager {
	
		/// This var return the current status of the location manager authorization session
	public static var locationAuthStatus: LocationServiceState {
		get {
			if CLLocationManager.locationServicesEnabled() == false {
				return .disabled
			} else {
				let status = CLLocationManager.authorizationStatus()
				switch status {
				case .notDetermined:
					return .undetermined
				case .denied:
					return .denied
				case .restricted:
					return .restricted
				case .authorizedAlways:
					return .authorized(always: true)
				case .authorizedWhenInUse:
					return .authorized(always: false)
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
		let hasAlwaysAuth = (Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil)
		let hasInUseAuth = (Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil)
		
		if hasAlwaysAuth == true { return .always }
		if hasInUseAuth == true { return .onlyInUse }
		return .none
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
	case ipScan = -1
	case any = 0
	case country = 1
	case city = 2
	case neighborhood = 3
	case block = 4
	case house = 5
	case room = 6
	case navigation = 7
	
	public var meters: Double {
		switch self {
		case .any:			return Double.infinity
		case .country:		return 100000.0
		case .city:			return kCLLocationAccuracyThreeKilometers
		case .neighborhood:	return kCLLocationAccuracyKilometer
		case .block:			return kCLLocationAccuracyHundredMeters
		case .house:			return kCLLocationAccuracyNearestTenMeters
		case .room:			return kCLLocationAccuracyBest
		case .navigation:	return kCLLocationAccuracyBestForNavigation
		case .ipScan:		return Double.infinity // Not used
		}
	}
	
	/**
	Validate a provided location against current value of the accuracy
	
	- parameter obj: provided location object
	
	- returns: true if location has an accuracy equal or grater than the one set by the struct itself
	*/
	internal func isLocationValidForAccuracy(_ obj: CLLocation) -> Bool {
		switch self {
		case .room, .navigation:
			return (obj.horizontalAccuracy < kCLLocationAccuracyNearestTenMeters)
		default:
			return (obj.horizontalAccuracy <= self.meters)
		}
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
	case continuous
	case oneShot
	case byDistanceIntervals(meters: Double)
	case significant
}

public func == (lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	switch (lhs,rhs) {
	case (.byDistanceIntervals(let d1), .byDistanceIntervals(let d2)) where d1 == d2:
		return true
	case (.continuous,.continuous), (.oneShot, .oneShot), (.significant, .significant):
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
	case (.continuous, _), (.oneShot, _):
		return true
	case (.byDistanceIntervals(let d1),.byDistanceIntervals(let d2)):
		return (e == true ? d1 <= d2 : d1 < d2)
	case (.significant, .significant):
		return true
	default:
		return false
	}
}

private func u_graterThan(includeEqual e: Bool, lhs: UpdateFrequency, rhs: UpdateFrequency) -> Bool {
	switch (lhs, rhs) {
	case (.significant, _):
		return true
	case (.byDistanceIntervals(let d1),.byDistanceIntervals(let d2)):
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
	case continuous(interval: TimeInterval?)
	case magneticNorth(minChange: CLLocationDirection)
	case trueNorth(minChange: CLLocationDirection)
}
