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

/// Thread-safe list
/// All functions and proprierties are thread-safe.
internal class SafeList<Value: Equatable> {
	
	/// Items
	private var _list: Array<Value> = []
	
	/// Serial DispatchQueue
	private var dispatchQueue: DispatchQueue = DispatchQueue(label: "SwiftLocation.SafeList.DispatchQueue")
	
	/// Safe items
	public var list: [Value] {
		get { return self.dispatchQueue.sync { self._list } }
	}
	
	/// Append new item
	///
	/// - Parameter item: append new item
	public func add(_ item: Value) {
		self.dispatchQueue.async { self._list.append(item) }
	}
	
	/// Remove existing item
	///
	/// - Parameter item: item to remove
	/// - Returns: `true` if exist and it was removed, `false` otherwise
	@discardableResult
	public func remove(_ item: Value) -> Bool {
		return self.dispatchQueue.sync {
			guard let idx = self._list.index(of: item) else { return false }
			self._list.remove(at: idx)
			return true
		}
	}
	
	/// Index of item.
	///
	/// - Parameter item: item
	/// - Returns: valid `Int` if item is in the list, `nil` if does not exists.
	public func index(of item: Value) -> Int? {
		return self.dispatchQueue.sync {
			guard let idx = self._list.index(of: item) else { return nil }
			return idx
		}
	}
	
	/// Number of items
	public var count: Int {
		return self.dispatchQueue.sync { self._list.count }
	}
}

/// IP Service
public enum IPService {
	case freeGeoIP
	case petabyet
	case smartIP
	case ipApi
	
	internal var url: URL {
		var url: String = ""
		switch self {
		case .freeGeoIP:	url = "https://freegeoip.net/json/"
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
public class GeocoderRequest: Equatable {
	
	/// Identifier of the operation
	public let identifier: String
	
	/// Success handler
	public var success: GeocoderRequest_Success?
	
	/// Failure handler
	public var failure: GeocoderRequest_Failure?

	/// Timeout interval
	public var timeout: TimeInterval?
	
	/// Operation of the request
	public let operation: GeocoderOperation
	
	/// Called when operation is finished
	internal var isFinished: Bool = false {
		didSet {
			if isFinished == true {
				Locator.geocoderRequests.remove(self)
			}
		}
	}
	
	/// Initialization of the geocoder request
	///
	/// - Parameter operation: operation to perform
	init(operation: GeocoderOperation, timeout: TimeInterval) {
		self.identifier = UUID().uuidString
		self.operation = operation
		self.timeout = timeout
	}
	
	/// Execute operation
	public func execute() {
		// nop
	}
	
	/// Cancel current execution (if any)
	public func cancel() {
		self.isFinished = true
	}
	
	public static func ==(lhs: GeocoderRequest, rhs: GeocoderRequest) -> Bool {
		return (lhs.identifier == rhs.identifier)
	}
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
            let hasAlwaysAndWhenInUse = hasPlistValue(forKey:"NSLocationAlwaysAndWhenInUseUsageDescription")
            let hasWhenInUse = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
			if hasAlwaysAndWhenInUse && hasWhenInUse {
				return .always
            } else if hasWhenInUse {
                return .whenInUse
			} else {
				// Key NSLocationWhenInUseUsageDescription MUST be present in the Info.plist file to use location services on iOS 11
                // For Always access NSLocationAlwaysAndWhenInUseUsageDescription must also be present.
				fatalError("To use location services in iOS 11+, your Info.plist must provide a value for NSLocationAlwaysUsageDescription and if requesting always access you must provide a value for  NSLocationAlwaysAndWhenInUseUsageDescription as well.")
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
			return hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription") &&
                   hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
		case .whenInUse:
			return hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
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
        self.task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            self?.onReceiveResponse(data, response, error)
        })
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

/// This is a generic object used to represent a Place; its shared along all geocoding services as common base.
public class Place: CustomStringConvertible {
	
	/// A user-friendly description of a geographic coordinate, often containing the name of the place,
	/// its address, and other relevant information.
	/// This is returned only from reverse geocoding using Apple's service, otherwise it will be `nil`.
	public internal(set) var placemark: CLPlacemark?
	
	/// Coordinates of the place
	public internal(set) var coordinates: CLLocationCoordinate2D?
	
	/// This string is the standard abbreviation used to refer to the country.
	/// For example, if the placemark location is Apple’s headquarters,
	/// the value for this property would be the string “US”.
	public internal(set) var countryCode: String?
	
	/// If the placemark location is Apple’s headquarters, for example,
	/// the value for this property would be the string “United States”.
	public internal(set) var country: String?
	
	
	@available(*, deprecated: 3.2.1, message: "Use administrativeArea property instead")
	public var state: String? {
		return self.administrativeArea
	}
	
	/// The string in this property can be either the spelled out name of the administrative
	/// area or its designated abbreviation, if one exists.
	/// If the placemark location is Apple’s headquarters, for example,
	/// the value for this property would be the string “CA” or “California”.
	public internal(set) var administrativeArea: String?
	
	@available(*, deprecated: 3.2.1, message: "Use subAdministrativeArea property instead")
	public var county: String? {
		return self.subAdministrativeArea
	}
	
	/// Subadministrative areas typically correspond to counties or other regions that
	/// are then organized into a larger administrative area or state.
	/// For example, if the placemark location is Apple’s headquarters,
	/// the value for this property would be the string “Santa Clara”,
	/// which is the county in California that contains the city of Cupertino.
	public internal(set) var subAdministrativeArea: String?

	@available(*, deprecated: 3.2.1, message: "Use locality property instead")
	public var neighborhood: String? {
		return self.locality
	}
	
	/// If the placemark location is Apple’s headquarters, for example,
	/// the value for this property would be the string “Cupertino”.
	public internal(set) var locality: String?

	/// This property contains additional information, such as the name of the neighborhood
	/// or landmark associated with the placemark. It might also refer to a common name
	/// that is associated with the location.
	public internal(set) var subLocality: String?
	
	@available(*, deprecated: 3.2.1, message: "Use postalCode property instead")
	public var postcode: String? {
		return self.postalCode
	}
	
	/// If the placemark location is Apple’s headquarters, for example, the value for this property would be the string “95014”.
	public internal(set) var postalCode: String?

	/// City
	public internal(set) var city: String?
	
	@available(*, deprecated: 3.2.1, message: "Use subAdministrativeArea property instead")
	public var cityDistrict: String? {
		return self.subAdministrativeArea
	}
	
	@available(*, deprecated: 3.2.1, message: "Use thoroughfare property instead")
	public var road: String? {
		return self.thoroughfare
	}
	
	/// The street address contains the street name.
	/// For example, if the placemark location is Apple’s headquarters,
	/// the value for this property would be the string “Infinite Loop”.
	public internal(set) var thoroughfare: String?

	@available(*, deprecated: 3.2.1, message: "Use subThoroughfare property instead")
	public var houseNumber: String? {
		return self.subThoroughfare
	}
	
	/// Subthroughfares provide information such as the street number for the location.
	/// For example, if the placemark location is Apple’s headquarters (1 Infinite Loop),
	/// the value for this property would be the string “1”.
	public internal(set) var subThoroughfare: String?

	/// The name of the placemark.
	public internal(set) var name: String?
	
	/// The relevant areas of interest associated with the placemark.
	public internal(set) var POI: String?
	
	/// Full address string
	public internal(set) var formattedAddress: String?
	
	/// Raw dictionary created from service
	public internal(set) var rawDictionary: [String:Any]?
	
	internal init() { }
	
	/// Initialize with Google raw service data
	///
	/// - Parameter json: input json
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
		self.name = ab(forType: "establishment")?["long_name"].string
		if let countryData = ab(forType: "country") {
			self.countryCode = countryData["short_name"].string
			self.country = countryData["long_name"].string
		}
		self.postalCode = ab(forType: "postal_code")?["long_name"].string
		self.administrativeArea = ab(forType: "administrative_area_level_1")?["long_name"].string
		self.subAdministrativeArea = ab(forType: "administrative_area_level_2")?["long_name"].string
		self.city = ab(forType: "locality")?["long_name"].string
		self.formattedAddress = json["formatted_address"].string
		
		self.locality = ab(forType: "neighborhood")?["long_name"].string ?? ab(forType: "sublocality_level_1")?["long_name"].string
		self.subLocality = ab(forType: "sublocality_level_2")?["long_name"].string
		self.thoroughfare = ab(forType: "route")?["long_name"].string
		if self.thoroughfare == nil {
			self.thoroughfare = ab(forType: "neighborhood")?["short_name"].string
		}
		self.subThoroughfare = ab(forType: "street_number")?["long_name"].string
		
		self.POI = ab(forType: "point_of_interest")?["long_name"].string
		self.rawDictionary = json.dictionaryObject
	}
	
	
	/// Initialize from Apple's raw service data
	///
	/// - Parameter placemark: data
	internal init?(placemark: CLPlacemark?) {
		guard let p = placemark else { return nil }
		self.placemark = p
		
		self.name = p.name
		self.coordinates = p.location?.coordinate
		self.rawDictionary = p.addressDictionary as? [String: Any]

		self.countryCode = p.isoCountryCode
		self.country = p.country
		
		self.administrativeArea = p.administrativeArea
		self.subAdministrativeArea = p.subAdministrativeArea
		self.locality = p.locality
		self.subLocality = p.subLocality

		self.postalCode = p.postalCode
		self.thoroughfare = p.thoroughfare
		self.subAdministrativeArea = p.subThoroughfare
		
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
