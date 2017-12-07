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
import SwiftyJSON

public enum IPService {
	case freeGeoIP
	case petabyet
	case smartIP
	case ipApi
	
	internal var url: URL {
		var url: String = ""
		switch self {
		case .freeGeoIP:	url = "http://freegeoip.net/json/"
		case .petabyet:		url = "http://api.petabyet.com/geoip/"
		case .smartIP:		url = "http://smart-ip.net/geoip-json/"
		case .ipApi:		url = "http://ip-api.com/json"
		}
		return URL(string: url)!
	}
}

/// Type of operation to perform
///
/// - getLocation: get location from address string (region is used only if service is Apple, otherwise it will be ignored)
/// - getPlace: get place info from location coordinates (preferred locale is used only if service is Apple, otherwise it will be ignored)
public enum GeocoderOperation {
	case getLocation(address: String, region: CLRegion?)
	case getPlace(coordinates: CLLocationCoordinate2D, locale: Locale?)
}

/// Supported geocoder services
///
/// - apple: apple built-in service
/// - openStreetMap: open street map service (nominatim.openstreetmap.org)
/// - google: google maps (require API key)
public enum GeocoderService {
	case apple
	case openStreetMap
	case google
	
	/// Create new request for given operation
	///
	/// - Parameter operation: operation to perform
	/// - Returns: request instance
	public func newRequest(operation: GeocoderOperation, timeout: TimeInterval?) -> GeocoderRequest {
		let t = timeout ?? 10
		switch self {
		case .openStreetMap:
			return Geocoder_OpenStreet(operation: operation, timeout: t)
		case .apple:
			return Geocoder_Apple(operation: operation, timeout: t)
		case .google:
			return Geocoder_Google(operation: operation, timeout: t)
		}
	}
}

/// Typealias for geocoder success
public typealias GeocoderRequest_Success = (([Place]) -> (Void))

/// Typealias for geocoder failure
public typealias GeocoderRequest_Failure = ((LocationError) -> (Void))

/// Protocol for geocoder request instance
public protocol GeocoderRequest {
	
	/// Success handler
	var success: GeocoderRequest_Success? { get set }
	
	/// Failure handler
	var failure: GeocoderRequest_Failure? { get set }

	/// Initialization of the geocoder request
	///
	/// - Parameter operation: operation to perform
	init(operation: GeocoderOperation, timeout: TimeInterval)

	/// Timeout interval
	var timeout: TimeInterval? { get set }
	
	/// Execute operation
	func execute()
	
	/// Cancel current execution (if any)
	func cancel()
}

/// Identifier type of the request
public typealias RequestID = String

/// General request protocol
public protocol Request { }

public class TimeoutManager {
	
	typealias Callback = (() -> (Void))

	/// This is the timeout interval
	public private(set) var interval: Timeout
	
	/// This is the start moment of the timeout
	public private(set) var start: Date? = nil
	
	/// Callback fired at the end of the timeout interval
	private var fireCallback: Callback? = nil
	
	/// Timer object
	private var timer: Timer? = nil
	
	/// Interval in seconds of the timeout
	var value: TimeInterval {
		switch self.interval {
		case .after(let t): return t
		case .delayed(let t): return t
		}
	}
	
	/// Return the remaining time from timeout session
	public var aliveTime: TimeInterval? {
		guard let s = self.start else { return nil }
		guard self.hasTimedout == false else { return 0 }
		return fabs(s.timeIntervalSinceNow)
	}
	
	/// Return `true` if timer has expired
	public var hasTimedout: Bool = false
	
	/// Initialize a new manager with given timeout interval
	///
	/// - Parameter timeout: interval
	internal init?(_ timeout: Timeout?, callback: @escaping Callback) {
		guard let t = timeout else { return nil }
		self.fireCallback = callback
		self.interval = t
	}
	
	/// Start timer. At the end of the timer callback handler will be called
	///
	/// - Parameter force: `true` to start timer regardeless the status of the request
	/// - Returns: `true` if timer started, `false` otherwise
	@discardableResult
	internal func startTimeout(force: Bool = false) -> Bool {
		if force == true || self.interval.shouldBeDelayed == false {
			self.hasTimedout = false
			self.reset()
			self.timer = Timer.scheduledTimer(timeInterval: self.value, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
			return true
		}
		return false
	}
	
	internal func forceTimeout() {
		self.abort()
	}
	
	/// Stop current timer
	internal func abort() {
		self.reset()
	}
	
	/// Objc function received on timer's fire event
	@objc func timerFired() {
		self.hasTimedout = true
		self.fireCallback?()
		self.reset()
	}
	
	/// Reset timer session and stop any other session
	private func reset() {
		self.timer?.invalidate()
		self.timer = nil
		self.start = Date()
	}
}


public extension CLLocationManager {
	
	/// Returns the current state of heading services for this device.
	public var headingState: HeadingServiceState {
		return (CLLocationManager.headingAvailable() ? .available : .unavailable)
	}
	
	/// Return `true` if host application has background location capabilities enabled
	public static var hasBackgroundCapabilities: Bool {
		guard let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
			return false
		}
		return capabilities.contains("location")
	}
	
	/// Return the highest authorization level based upon the value added info applications'
	/// Info.plist file.
	public static var authorizationLevelFromInfoPlist: AuthorizationLevel {
		let osVersion = (UIDevice.current.systemVersion as NSString).floatValue

		if osVersion < 11 {
			let hasAlwaysKey = 	hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") &&
								hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
			let hasWhenInUse = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
			if hasAlwaysKey {
				return .always
			} else if hasWhenInUse {
				return .whenInUse
			} else {
				// At least one of the keys NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription MUST
				// be present in the Info.plist file to use location services on iOS 8+.
				fatalError("To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.")
			}
		} else {
			// In iOS11 stuff are changed again
			let hasAlwaysAndInUseKey = hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
			if hasAlwaysAndInUseKey {
				return .always
			} else {
				// Key NSLocationAlwaysAndWhenInUseUsageDescription MUST be present in the Info.plist
				// file to use location services on iOS 11+.
				fatalError("To use location services in iOS 11+, your Info.plist must provide a value for NSLocationAlwaysAndWhenInUseUsageDescription.")
			}
		}
	}
	
	
	/// Check if application's Info.plist key has valid values for privacy settings for the required authorization level
	///
	/// - Parameter level: level you want to set
	/// - Returns: `true` if valid
	public static func validateInfoPlistRequiredKeys(forLevel level: AuthorizationLevel) -> Bool {
		let osVersion = (UIDevice.current.systemVersion as NSString).floatValue
		switch level {
		case .always:
			if osVersion < 11 {
				return 	(hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") ||
						hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription"))
				
			}
			return hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
		case .whenInUse:
			if osVersion < 11 { return hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription") }
			return hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
		}
	}
	
	
	/// Validate and request authorization level
	///
	/// - Parameter level: level to require
	public func requestAuthorization(level: AuthorizationLevel) {
		// Validate the level you want to set before doing a request
		if CLLocationManager.validateInfoPlistRequiredKeys(forLevel: level) == false {
			fatalError("Missing Info.plist entries for required authorization level")
		}
		switch level {
		case .always:
			self.requestAlwaysAuthorization()
		case .whenInUse:
			self.requestWhenInUseAuthorization()
		}
	}
	
	/// Return is specified value is set in Info.plist of the host application
	///
	/// - Parameter key: key to validate
	/// - Returns: `true` if exists
	private static func hasPlistValue(forKey key: String) -> Bool {
		guard let dict = Bundle.main.infoDictionary else { return false }
		return ((dict[key] as? String)?.isEmpty ?? true == false)
	}
	
	/// Current state of the authorization service
	public var serviceState: ServiceState {
		guard CLLocationManager.locationServicesEnabled() else {
			return .disabled
		}
		switch CLLocationManager.authorizationStatus() {
		case .notDetermined:
			return .notDetermined
		case .denied:
			return .denied
		case .restricted:
			return .restricted
		default:
			return .available
		}
	}
	
	/// Are services available
	public var servicesAreAvailable: Bool {
		switch self.serviceState {
		case .disabled, .denied, .restricted:
			return false
		default:
			return true
		}
	}
}

/// Desidered accuracy of the request.
/// An abstraction of both the horizontal accuracy and recency of location data.
/// `room` is the highest level of accuracy/recency; `ip` is the lowest level
///
/// - any: inaccurate (>5000 meters, and/or received >10 minutes ago)
/// - city: 5000 meters or better, and received within the last 10 minutes. Lowest accuracy
/// - neighborhood: 1000 meters or better, and received within the last 5 minutes
/// - block: 15 meters or better, and received within the last 15 seconds
/// - house: 100 meters or better, and received within the last 1 minute
/// - room: 5 meters or better, and received within the last 5 seconds. Highest accuracy
public enum Accuracy: Int, Equatable, Comparable, CustomStringConvertible {
	
	case any = 0
	case city
	case neighborhood
	case block
	case house
	case room
	
	/// Initialize a new accuracy level from raw value provided by the location manager.
	/// The nearest value is used.
	///
	/// - Parameter accuracy: nearest accuracy level
	public init(_ accuracy: CLLocationAccuracy) {
		switch accuracy {
		case Accuracy.any.threshold:			self = .any
		case Accuracy.neighborhood.threshold:	self = .neighborhood
		case Accuracy.block.threshold:			self = .block
		case Accuracy.house.threshold:			self = .house
		case Accuracy.room.threshold:			self = .room
		default:
			// find the closest match
			let values: [CLLocationAccuracy:Accuracy] = [
				Accuracy.any.threshold 			: .any,
				Accuracy.neighborhood.threshold : .neighborhood,
				Accuracy.block.threshold		: .block,
				Accuracy.house.threshold 		: .house,
				Accuracy.room.threshold 		: .room
			]
			var bestAccuracy: Accuracy = .any
			var bestDelta = Double.infinity
			values.enumerated().forEach({ (_,element) in
				let delta = fabs(element.key - accuracy)
				if delta < bestDelta {
					bestAccuracy = element.value
					bestDelta = delta
				}
			})
			self = bestAccuracy
		}
	}
	
	/// Associated horizontal accuracy threshold (in meters) for the
	/// location request's desired accuracy level.
	public var threshold: CLLocationAccuracy {
		switch self {
		case .any:				return Double.infinity
		case .city:				return 5000.0
		case .neighborhood:		return 1000.0
		case .block:			return 100.0
		case .house:			return 15.0
		case .room:				return 5.0
		}
	}
	
	/// Associated recency threshold (in seconds) for the location request's
	/// desired accuracy level.
	public var timeStaleThreshold: TimeInterval {
		switch self {
		case .any:				return 1.0
		case .city:				return 600.0
		case .neighborhood:		return 300.0
		case .block:			return 60.0
		case .house:			return 15.0
		case .room:				return 5
		}
	}
	
	/// Validate provided request for location request object.
	/// If not valid the default fallback is returned along side a message.
	internal var validateForGPSRequest: Accuracy {
		guard self != .any else {
			debugPrint("Accuracy \(self) is not acceptable for GPS location request. Using .city instead")
			return .city
		}
		return self
	}
	
	public var description: String {
		switch self {
		case .any:				return "any"
		case .city:				return "city"
		case .neighborhood:		return "neighborhood"
		case .block:			return "block"
		case .house:			return "house"
		case .room:				return "room"
		}
	}
	
	public static func <(lhs: Accuracy, rhs: Accuracy) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}
}

/// Timeout interval of the request. `nil` values for this object means no timeout is required.
///
/// - after: timeout occours after specified interval regardeless the needs of authorizations from the user.
/// - delayed: countdown will not begin until after the app receives location services permissions from the user.
public enum Timeout {
	case after(_: TimeInterval)
	case delayed(_: TimeInterval)
	
	/// Timer start should be delayed or not?
	public var shouldBeDelayed: Bool {
		if case .delayed = self, CLLocationManager.authorizationStatus() == .notDetermined {
			return true
		}
		return false
	}
}

/// The possible states that location services can be in.
///
/// - available: User has already granted this app permissions to access location services, and they are enabled and ready for use by this app. Note: this state will be returned for both the "When In Use" and "Always" permission levels
/// - notDetermined: User has not yet responded to the dialog that grants this app permission to access location services.
/// - denied: User has explicitly denied this app permission to access location services. (The user can enable permissions again for this app from the system Settings app.)
/// - restricted: User does not have ability to enable location services (e.g. parental controls, corporate policy, etc).
/// - disabled: User has turned off location services device-wide (for all apps) from the system Settings app.
public enum ServiceState {
	case available
	case notDetermined
	case denied
	case restricted
	case disabled
}

/// Location authorization level you want to ask to the user
///
/// - always: always (both in background and foreground)
/// - whenInUse: only in foreground
public enum AuthorizationLevel {
	case always
	case whenInUse
}

/// A status that will be passed in to the completion block of a location request
///
/// - timedout: got a location (see `location` of the request), but the desired accuracy level was not reached before timeout.
///             (Not applicable to subscriptions.)
/// - notDetermined: nil location. User has not yet responded to the dialog that grants this app permission to access location services.
/// - denied: nil location. User has explicitly denied this app permission to access location services
/// - restricted: nil location. User does not have ability to enable location services (e.g. parental controls, corporate policy, etc)
/// - disabled: nil location. User has turned off location services device-wide (for all apps) from the system Settings app.
/// - error: nil location. An error occurred while using the system location services
/// - missingAPIKey: You must set the API key in `api` property of the Locator object
public enum LocationError: Error {
	case timedout
	case notDetermined
	case denied
	case restricted
	case disabled
	case error
	case other(_: String)
	case dataParserError
	case missingAPIKey(forService: String)
	case failedToObtainData
}

/// The possible states that heading services can be in
///
/// - available: Heading services are available on the device
/// - unavailable: Heading services are available on the device
public enum HeadingServiceState {
	case available
	case unavailable
	case invalid
}

/// JSON operastion is used to get data from specified url and return a valid json parsed result using SwiftyJSON
public class JSONOperation {
	
	/// Task of the operation
	private var task: URLSessionDataTask?
	
	/// Callback called on success
	public var onSuccess: ((JSON) -> (Void))? = nil
	
	/// Callack called on failure
	public var onFailure: ((LocationError) -> (Void))? = nil
	
	/// Initialize a new download operation with given url
	///
	/// - Parameters:
	///   - url: url to download
	///   - timeout: timeout, `nil` uses default timeout (10 seconds)
	public init(_ url: URL, timeout: TimeInterval? = nil) {
		let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout ?? 10)
		self.task = URLSession.shared.dataTask(with: request, completionHandler: self.onReceiveResponse)
	}
	
	/// Response parser
	///
	/// - Parameters:
	///   - data: data received if any
	///   - response: url response if any
	///   - error: error if any
	private func onReceiveResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
		if let e = error {
			self.onFailure?(LocationError.other(e.localizedDescription))
			return
		}
		guard let d = data else {
			self.onFailure?(LocationError.dataParserError)
			return
		}
		do {
			let json = try JSON(data: d)
			self.onSuccess?(json)
		} catch {
			self.onFailure?(LocationError.dataParserError)
		}
	}
	
	/// Execute download and parse
	public func execute() {
		self.task?.resume()
	}
	
	/// Cancel operation
	public func cancel() {
		self.task?.cancel()
	}
	
}

public class Place: CustomStringConvertible {
	public internal(set) var placemark: CLPlacemark?
	public internal(set) var coordinates: CLLocationCoordinate2D?
	public internal(set) var countryCode: String?
	public internal(set) var country: String?
	public internal(set) var state: String?
	public internal(set) var county: String?
	public internal(set) var postcode: String?
	public internal(set) var city: String?
	public internal(set) var cityDistrict: String?
	public internal(set) var road: String?
	public internal(set) var houseNumber: String?
	public internal(set) var name: String?
	public internal(set) var POI: String?
	public internal(set) var rawDictionary: [String:Any]?
	
	internal init() { }
	
	internal init(googleJSON json: JSON) {
		func ab(forType type: String) -> JSON? {
			return json["address_components"].arrayValue.first(where: { data in
				return data["types"].arrayValue.contains(where: { entry in
					return entry.stringValue == type
				})
			})
		}
		
		if let lat = json["geometry"]["location"]["lat"].double, let lon = json["geometry"]["location"]["lng"].double {
			self.coordinates = CLLocationCoordinate2DMake(lat, lon)
		}
		self.name = ab(forType: "establishment")?["short_name"].string
		if let countryData = ab(forType: "country") {
			self.countryCode = countryData["short_name"].string
			self.country = countryData["long_name"].string
		}
		self.postcode = ab(forType: "postal_code")?["short_name"].string
		self.state = ab(forType: "administrative_area_level_1")?["short_name"].string
		self.city = ab(forType: "locality")?["short_name"].string
		self.cityDistrict = ab(forType: "administrative_area_level_2")?["short_name"].string
		self.road = ab(forType: "route")?["short_name"].string
		if self.road == nil {
			self.road = ab(forType: "neighborhood")?["short_name"].string
		}
		self.houseNumber = ab(forType: "street_number")?["short_name"].string
		self.POI = ab(forType: "point_of_interest")?["short_name"].string
		self.rawDictionary = json.dictionaryObject
	}
	
	internal init?(placemark: CLPlacemark?) {
		guard let p = placemark else { return nil }
		self.placemark = p
		
		self.name = p.name
		self.coordinates = p.location?.coordinate
		self.countryCode = p.isoCountryCode
		self.country = p.country
		self.postcode = p.postalCode
		self.cityDistrict = p.administrativeArea
		self.road = p.thoroughfare
		self.houseNumber = p.subAdministrativeArea
		
		if #available(iOS 11.0, *) {
			if let address = p.postalAddress {
				self.city = address.city
			}
		} else {
			self.city = p.locality
		}
	}
	
	internal static func load(placemarks: [CLPlacemark]) -> [Place] {
		return placemarks.flatMap { Place(placemark: $0) }
	}
	
	public var description: String {
		return self.name ?? "Unknown Place"
	}
}

internal extension String {
	
	var urlEncoded: String {
		return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
	}
}

