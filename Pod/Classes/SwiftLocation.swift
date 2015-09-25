//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2015 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
// First version: July 15, 2015
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


import UIKit
import CoreLocation
import MapKit

enum SwiftLocationError: ErrorType {
	case ServiceUnavailable
	case LocationServicesUnavailable
}

/// Type of a request ID
public typealias RequestIDType = Int

//MARK: Handlers
// Location related handler
public typealias onSuccessLocate = ( (location: CLLocation?) -> Void)
public typealias onErrorLocate = ( (error: NSError?) -> Void )
// Generic timeout handler
public typealias onTimeoutReached = ( Void -> (NSTimeInterval?) )
// Region/Beacon Proximity related handlers
public typealias onRegionEvent = ( (region: AnyObject?) -> Void)
public typealias onRangingBacon = ( (beacons: [AnyObject]) -> Void)
// Geocoding related handlers
public typealias onSuccessGeocoding = ( (place: CLPlacemark?) -> Void)
public typealias onErrorGeocoding = ( (error: NSError?) -> Void)

//MARK: Service Status Enum

/**
Apple location services are subject to authorization step. This enum indicate the current status of the location manager into the device. You can query it via SwiftLocation.state property.

- Available:    User has already granted this app permissions to access location services, and they are enabled and ready for use by this app.
Note: this state will be returned for both the "When In Use" and "Always" permission levels.
- Undetermined: User has not yet responded to the dialog that grants this app permission to access location services.
- Denied:       User has explicitly denied this app permission to access location services. (The user can enable permissions again for this app from the system Settings app.)
- Restricted:   User does not have ability to enable location services (e.g. parental controls, corporate policy, etc).
- Disabled:     User has turned off location services device-wide (for all apps) from the system Settings app.
*/
public enum ServiceStatus :Int {
	case Available
	case Undetermined
	case Denied
	case Restricted
	case Disabled
}

//MARK: Service Type Enum

/**
For reverse geocoding service you can choose what service use to make your request.

- Apple:      Apple built-in CoreLocation services
- GoogleMaps: Google Geocoding Services (https://developers.google.com/maps/documentation/geocoding/intro)
*/
public enum Service: Int, CustomStringConvertible {
	case Apple		= 0
	case GoogleMaps = 1
	
	public var description: String {
		get {
			switch self {
			case .Apple:
				return "Apple"
			case .GoogleMaps:
				return "Google"
			}
		}
	}
}

//MARK: Accuracy

/**
Accuracy is used to set the minimum level of precision required during location discovery

- None:         Unknown level detail
- Country:      Country detail. It's used only for a single shot location request and uses IP based location discovery (no auth required). Inaccurate (>5000 meters, and/or received >10 minutes ago).
- City:         5000 meters or better, and received within the last 10 minutes. Lowest accuracy.
- Neighborhood: 1000 meters or better, and received within the last 5 minutes.
- Block:        100 meters or better, and received within the last 1 minute.
- House:        15 meters or better, and received within the last 15 seconds.
- Room:         5 meters or better, and received within the last 5 seconds. Highest accuracy.
*/
public enum Accuracy:Int, CustomStringConvertible {
	case None			= 0
	case Country		= 1
	case City			= 2
	case Neighborhood	= 3
	case Block			= 4
	case House			= 5
	case Room			= 6
	
	public var description: String {
		get {
			switch self {
			case .None:
				return "None"
			case .Country:
				return "Country"
			case .City:
				return "City"
			case .Neighborhood:
				return "Neighborhood"
			case .Block:
				return "Block"
			case .House:
				return "House"
			case .Room:
				return "Room"
			}
		}
	}
	
	/**
	This is the threshold of accuracy to validate a location
	
	- returns: value in meters
	*/
	func accuracyThreshold() -> Double {
		switch self {
		case .None:
			return Double.infinity
		case .Country:
			return Double.infinity
		case .City:
			return 5000.0
		case .Neighborhood:
			return 1000.0
		case .Block:
			return 100.0
		case .House:
			return 15.0
		case .Room:
			return 5.0
		}
	}
	
	/**
	Time threshold to validate the accuracy of a location
	
	- returns: in seconds
	*/
	func timeThreshold() -> Double {
		switch self {
		case .None:
			return Double.infinity
		case .Country:
			return Double.infinity
		case .City:
			return 600.0
		case .Neighborhood:
			return 300.0
		case .Block:
			return 60.0
		case .House:
			return 15.0
		case .Room:
			return 5.0
		}
	}
}

//MARK: ===== [PUBLIC] SwiftLocation Class =====

public class SwiftLocation: NSObject, CLLocationManagerDelegate {
	//MARK: Private vars
	private var manager: CLLocationManager // CoreLocationManager shared instance
	private var requests: [SwiftLocationRequest]! // This is the list of running requests (does not include geocode requests)
	private let blocksDispatchQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL) // sync operation queue for CGD
	
	//MARK: Public vars
	public static let shared = SwiftLocation()
	
	//MARK: Simulate location and location updates
	
	/// Set this to a valid non-nil location to receive it as current location for single location search
	public var fixedLocation: CLLocation?
	public var fixedLocationDictionary: [String: AnyObject]?
	/// Set it to a valid existing gpx file url to receive positions during continous update
	//public var fixedLocationGPX: NSURL?
	
	
	/// This property report the current state of the CoreLocationManager service based on user authorization
	class var state: ServiceStatus {
		get {
			if CLLocationManager.locationServicesEnabled() == false {
				return .Disabled
			} else {
				switch CLLocationManager.authorizationStatus() {
				case .NotDetermined:
					return .Undetermined
				case .Denied:
					return .Denied
				case .Restricted:
					return .Restricted
				case .AuthorizedAlways, .AuthorizedWhenInUse:
					return .Available
				}
			}
		}
	}
	
	//MARK: Private Init
	
	/**
	Private init. This is called only to allocate the singleton instance
	
	- returns: the object itself, what else?
	*/
	override private init() {
		requests = []
		manager = CLLocationManager()
		super.init()
		manager.delegate = self
	}
	
	//MARK: [Public] Cancel a running request
	
	/**
	Cancel a running request
	
	- parameter identifier: identifier of the request
	
	- returns: true if request is marked as cancelled, no if it was not found
	*/
	public func cancelRequest(identifier: Int) -> Bool {
		if let request = request(identifier) as SwiftLocationRequest! {
			request.markAsCancelled(nil)
		}
		return false
	}
	
	/**
	Mark as cancelled any running request
	*/
	public func cancelAllRequests() {
		for request in requests {
			request.markAsCancelled(nil)
		}
	}
	
	//MARK: [Public] Reverse Geocoding

	/**
	Submits a forward-geocoding request using the specified string and optional region information.
	
	- parameter service:    service to use
	- parameter address:   A string describing the location you want to look up. For example, you could specify the string “1 Infinite Loop, Cupertino, CA” to locate Apple headquarters.
	- parameter region:    (Optional) A geographical region to use as a hint when looking up the specified address. Region is used only when service is set to Apple
	- parameter onSuccess: on success handler
	- parameter onFail:    on error handler
	*/
	public func reverseAddress(service: Service!, address: String!, region: CLRegion?, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding? ) {
		if service == Service.Apple {
			reverseAppleAddress(address, region: region, onSuccess: onSuccess, onFail: onFail)
		} else {
			reverseGoogleAddress(address, onSuccess: onSuccess, onFail: onFail)
		}
	}
	
	/**
	This method submits the specified location data to the geocoding server asynchronously and returns.
	
	- parameter service:     service to use
	- parameter coordinates: coordinates to reverse
	- parameter onSuccess:	on success handler with CLPlacemarks objects
	- parameter onFail:		on error handler with error description
	*/
	public func reverseCoordinates(service: Service!, coordinates: CLLocationCoordinate2D!, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding? ) {
		if service == Service.Apple {
			reverseAppleCoordinates(coordinates, onSuccess: onSuccess, onFail: onFail)
		} else {
			reverseGoogleCoordinates(coordinates, onSuccess: onSuccess, onFail: onFail)
		}
	}
	
	//MARK: [Public] Search Location / Subscribe Location Changes
	
	/**
	Get the current location from location manager with given accuracy
	
	- parameter accuracy:  minimum accuracy value to accept (country accuracy uses IP based location, not the CoreLocationManager, and it does not require user authorization)
	- parameter timeout:   search timeout. When expired, method return directly onFail
	- parameter onSuccess: handler called when location is found
	- parameter onFail:    handler called when location manager fails due to an error
	
	- returns: return an object to manage the request itself
	*/
	public func currentLocation(accuracy: Accuracy, timeout: NSTimeInterval, onSuccess: onSuccessLocate, onFail: onErrorLocate) throws -> RequestIDType {
		if let fixedLocation = fixedLocation as CLLocation! {
			// If a fixed location is set we want to return it
			onSuccess(location: fixedLocation)
			return -1 // request cannot be aborted, of course
		}
		
		if SwiftLocation.state == ServiceStatus.Disabled {
			throw SwiftLocationError.LocationServicesUnavailable
		}
		
		if accuracy == Accuracy.Country {
			let newRequest = SwiftLocationRequest(requestType: RequestType.SingleShotIPLocation, accuracy:accuracy, timeout: timeout, success: onSuccess, fail: onFail)
			locateByIP(newRequest, refresh: false, timeout: timeout, onEnd: { (place, error) -> Void in
				if error != nil {
					onFail(error: error)
				} else {
					onSuccess(location: place?.location)
				}
			})
			addRequest(newRequest)
			return newRequest.ID
		} else {
			let newRequest = SwiftLocationRequest(requestType: RequestType.SingleShotLocation, accuracy:accuracy, timeout: timeout, success: onSuccess, fail: onFail)
			addRequest(newRequest)
			return newRequest.ID
		}
	}
	
	/**
	This method continously report found locations with desidered or better accuracy. You need to stop it manually by calling cancel() method into the request.
	
	- parameter accuracy:  minimum accuracy value to accept (country accuracy is not allowed)
	- parameter onSuccess: handler called each time a new position is found
	- parameter onFail:    handler called when location manager fail (the request itself is aborted automatically)
	
	- returns: return the id of the request. Use cancelRequest() to abort it.
	*/
	public func continuousLocation(accuracy: Accuracy, onSuccess: onSuccessLocate, onFail: onErrorLocate) throws -> RequestIDType {
		if SwiftLocation.state == ServiceStatus.Disabled {
			throw SwiftLocationError.LocationServicesUnavailable
		}
		let newRequest = SwiftLocationRequest(requestType: RequestType.ContinuousLocationUpdate, accuracy:accuracy, timeout: 0, success: onSuccess, fail: onFail)
		addRequest(newRequest)
		return newRequest.ID
	}
	
	/**
	This method continously return only significant location changes. This capability provides tremendous power savings for apps that want to track a user’s approximate location and do not need highly accurate position information. You need to stop it manually by calling cancel() method into the request.
	
	- parameter onSuccess: handler called each time a new position is found
	- parameter onFail:    handler called when location manager fail (the request itself is aborted automatically)
	
	- returns: return the id of the request. Use cancelRequest() to abort it.
	*/
	public func significantLocation(onSuccess: onSuccessLocate, onFail: onErrorLocate) throws -> RequestIDType {
		if SwiftLocation.state == ServiceStatus.Disabled {
			throw SwiftLocationError.LocationServicesUnavailable
		}
		let newRequest = SwiftLocationRequest(requestType: RequestType.ContinuousSignificantLocation, accuracy:Accuracy.None, timeout: 0, success: onSuccess, fail: onFail)
		addRequest(newRequest)
		return newRequest.ID
	}
	
	//MARK: [Public] Monitor Regions

	/**
	Start monitoring specified region by reporting when users move in/out from it. You must call this method once for each region you want to monitor. You need to stop it manually by calling cancel() method into the request.
	
	- parameter region:  region to monitor
	- parameter onEnter: handler called when user move into the region
	- parameter onExit:  handler called when user move out from the region
	
	- returns: return the id of the request. Use cancelRequest() to abort it.
	*/
	public func monitorRegion(region: CLRegion!, onEnter: onRegionEvent?, onExit: onRegionEvent?) throws -> RequestIDType? {
		// if beacons region monitoring is not available on this device we can't satisfy the request
		let isAvailable = CLLocationManager.isMonitoringAvailableForClass(CLRegion.self)
		if isAvailable == true {
			let request = SwiftLocationRequest(region: region, onEnter: onEnter, onExit: onExit)
			manager.startMonitoringForRegion(region)
			self.updateLocationManagerStatus()
			return request.ID
		} else {
			throw SwiftLocationError.ServiceUnavailable
		}
	}
	
	//MARK: [Public] Monitor Beacons Proximity

	/**
	Starts the delivery of notifications for beacons in the specified region.
	
	- parameter region:    region to monitor
	- parameter onRanging: handler called every time one or more beacon are in range, ordered by distance (closest is the first one)
	
	- returns: return the id of the request. Use cancelRequest() to abort it.
	*/
	public func monitorBeaconsInRegion(region: CLBeaconRegion!, onRanging: onRangingBacon? ) throws -> RequestIDType? {
		let isAvailable = CLLocationManager.isRangingAvailable() // if beacons monitoring is not available on this device we can't satisfy the request
		if isAvailable == true {
			let request = SwiftLocationRequest(beaconRegion: region, onRanging: onRanging)
			addRequest(request)
			return request.ID
		} else {
			throw SwiftLocationError.ServiceUnavailable
		}
	}
	
	//MARK: [Private] Google / Reverse Geocoding
	
	private func reverseGoogleCoordinates(coordinates: CLLocationCoordinate2D!, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding? ) {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(coordinates.latitude),\(coordinates.longitude)" as NSString
		APIURLString = APIURLString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
		let APIURL = NSURL(string: APIURLString as String)
		let APIURLRequest = NSURLRequest(URL: APIURL!)
		NSURLConnection.sendAsynchronousRequest(APIURLRequest, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
			if error != nil {
				onFail?(error: error)
			} else {
                if data != nil {
                    let jsonResult: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
                    let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
                    if noResults == true { // request is ok but not results are returned
                        onSuccess?(place: nil)
                    } else if (error != nil) { // something went wrong with request
                        onFail?(error: error)
                    } else { // we have some good results to show
                        let address = SwiftLocationParser()
                        address.parseGoogleLocationData(jsonResult)
                        let placemark:CLPlacemark = address.getPlacemark()
                        onSuccess?(place: placemark)
                    }
                }
			}
		}
	}
	
	private func reverseGoogleAddress(address: String!, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding?) {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)" as NSString
		APIURLString = APIURLString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
		let APIURL = NSURL(string: APIURLString as String)
		let APIURLRequest = NSURLRequest(URL: APIURL!)
		NSURLConnection.sendAsynchronousRequest(APIURLRequest, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
			if error != nil {
				onFail?(error: error)
			} else {
                if data != nil {
                    let jsonResult: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
                    let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
                    if noResults == true { // request is ok but not results are returned
                        onSuccess?(place: nil)
                    } else if (error != nil) { // something went wrong with request
                        onFail?(error: error)
                    } else { // we have some good results to show
                        let address = SwiftLocationParser()
                        address.parseGoogleLocationData(jsonResult)
                        let placemark:CLPlacemark = address.getPlacemark()
                        onSuccess?(place: placemark)
                    }
                }
			}
		}
	}
	
	private func validateGoogleJSONResponse(jsonResult: NSDictionary!) -> (error: NSError?, noResults: Bool!) {
		var status = jsonResult.valueForKey("status") as! NSString
		status = status.lowercaseString
		if status.isEqualToString("ok") == true { // everything is fine, the sun is shining and we have results!
			return (nil,false)
		} else if status.isEqualToString("zero_results") == true { // No results error
			return (nil,true)
		} else if status.isEqualToString("over_query_limit") == true { // Quota limit was excedeed
			let message	= "Query quota limit was exceeded"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		} else if status.isEqualToString("request_denied") == true { // Request was denied
			let message	= "Request denied"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		} else if status.isEqualToString("invalid_request") == true { // Invalid parameters
			let message	= "Invalid input sent"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		}
		return (nil,false) // okay!
	}
	
	//MARK: [Private] Apple / Reverse Geocoding
	
	private func reverseAppleCoordinates(coordinates: CLLocationCoordinate2D!, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding?  ) {
		let geocoder = CLGeocoder()
		let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
		geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
			if error != nil {
				onFail?(error: error)
			} else {
				if let placemark = placemarks?[0] {
					let address = SwiftLocationParser()
					address.parseAppleLocationData(placemark)
					onSuccess?(place: address.getPlacemark())
				} else {
					onSuccess?(place: nil)
				}
			}
		})
	}
	
	private func reverseAppleAddress(address: String!, region: CLRegion?, onSuccess: onSuccessGeocoding?, onFail: onErrorGeocoding? ) {
		let geocoder = CLGeocoder()
		if region != nil {
			geocoder.geocodeAddressString(address, inRegion: region, completionHandler: { (placemarks, error) in
				if error != nil {
					onFail?(error: error)
				} else {
					if let placemark = placemarks?[0]  {
						let address = SwiftLocationParser()
						address.parseAppleLocationData(placemark)
						onSuccess?(place: address.getPlacemark())
					} else {
						onSuccess?(place: nil)
					}
				}
			})
		} else {
			geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
				if error != nil {
					onFail?(error: error)
				} else {
					if let placemark = placemarks?[0] {
						let address = SwiftLocationParser()
						address.parseAppleLocationData(placemark)
						onSuccess?(place: address.getPlacemark())
					} else {
						onSuccess?(place: nil)
					}
				}
			})
		}
	}
	
	//MARK: [Private] Helper Methods
	
	private func locateByIP(request: SwiftLocationRequest, refresh: Bool = false, timeout: NSTimeInterval, onEnd: ( (place: CLPlacemark?, error: NSError?) -> Void)? ) {
		let policy = (refresh == false ? NSURLRequestCachePolicy.ReturnCacheDataElseLoad : NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData)
		let URLRequest = NSURLRequest(URL: NSURL(string: "https://ip-api.com/json")!, cachePolicy: policy, timeoutInterval: timeout)
        NSURLConnection.sendAsynchronousRequest(URLRequest, queue: NSOperationQueue.mainQueue()) { response, data, error in
            if request.isCancelled == true {
                onEnd?(place: nil, error: nil)
                return
            }
            if let data = data as NSData? {
                do {
                    if let resultDict = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary {
                        let address = SwiftLocationParser()
                        address.parseIPLocationData(resultDict)
                        let placemark = address.getPlacemark()
                        onEnd?(place: placemark, error:nil)
                    }
                } catch let error {
                    onEnd?(place: nil, error: NSError(domain: "\(error)", code: 1, userInfo: nil))
                }
            }
        }
	}
	
	/**
	Request will be added to the pool and related services are enabled automatically
	
	- parameter request: request to add
	*/
	private func addRequest(request: SwiftLocationRequest!) {
		// Add a new request to the array. Please note: add/remove is a sync operation due to avoid problems in a multitrheading env
		dispatch_sync(blocksDispatchQueue) {
			self.requests.append(request)
			self.updateLocationManagerStatus()
		}
	}
	
	/**
	Search for a request with given identifier into the pool of requests
	
	- parameter identifier: identifier of the request
	
	- returns: the request object or nil
	*/
	private func request(identifier: Int?) -> SwiftLocationRequest? {
		if let identifier = identifier as Int! {
			for cRequest in self.requests {
				if cRequest.ID == identifier {
					return cRequest
				}
			}
		}
		return nil
	}
	
	/**
	Return the requesta associated with a given CLRegion object
	
	- parameter region: region instance
	
	- returns: request if found, nil otherwise.
	*/
	private func requestForRegion(region: CLRegion!) -> SwiftLocationRequest? {
		for request in requests {
			if request.type == RequestType.RegionMonitor && request.region == region {
				return request
			}
		}
		return nil
	}
	
	/**
	This method is called to complete an existing request, send result to the appropriate handler and remove it from the pool
	(the last action will not occur for subscribe continuosly location notifications, until the request is not marked as cancelled)
	
	- parameter request: request to complete
	- parameter object:  optional return object
	- parameter error:   optional error to report
	*/
	private func completeRequest(request: SwiftLocationRequest!, object: AnyObject?, error: NSError?) {
		
		if request.type == RequestType.RegionMonitor { // If request is a region monitor we need to explictly stop it
			manager.stopMonitoringForRegion(request.region!)
		} else if (request.type == RequestType.BeaconRegionProximity) { // If request is a proximity beacon monitor we need to explictly stop it
			manager.stopRangingBeaconsInRegion(request.beaconReg!)
		}
		
		// Sync remove item from requests pool
		dispatch_sync(blocksDispatchQueue) {
			var idx = 0
			for cRequest in self.requests {
				if cRequest.ID == request.ID {
					cRequest.stopTimeout() // stop any running timeout timer
					if	cRequest.type == RequestType.ContinuousSignificantLocation ||
						cRequest.type == RequestType.ContinuousLocationUpdate ||
						cRequest.type == RequestType.SingleShotLocation ||
						cRequest.type == RequestType.SingleShotIPLocation ||
						cRequest.type == RequestType.BeaconRegionProximity {
						// for location related event we want to report the last fetched result
						if error != nil {
							cRequest.onError?(error: error)
						} else {
							if object != nil {
								cRequest.onSuccess?(location: object as! CLLocation?)
							}
						}
					}
					// If result is not continous location update notifications or, anyway, for any request marked as cancelled
					// we want to remove it from the pool
					if cRequest.isCancelled == true || cRequest.type != RequestType.ContinuousLocationUpdate {
						self.requests.removeAtIndex(idx)
					}
				}
				idx++
			}
			// Turn off any non-used hardware based upon the new list of running requests
			self.updateLocationManagerStatus()
		}
	}
	
	/**
	This method return the highest accuracy you want to receive into the current bucket of requests
	
	- returns: highest accuracy level you want to receive
	*/
	private func highestRequiredAccuracy() -> CLLocationAccuracy {
		var highestAccuracy = CLLocationAccuracy(Double.infinity)
		for request in requests {
			let accuracyLevel = CLLocationAccuracy(request.desideredAccuracy.accuracyThreshold())
			if accuracyLevel < highestAccuracy {
				highestAccuracy = accuracyLevel
			}
		}
		return highestAccuracy
	}
	
	/**
	This method simply turn off/on hardware required by the list of active running requests.
	The same method also ask to the user permissions to user core location.
	*/
	private func updateLocationManagerStatus() {
		if requests.count > 0 {
			let hasAlwaysKey = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") != nil)
			let hasWhenInUseKey = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription") != nil)
			if hasAlwaysKey == true {
				manager.requestAlwaysAuthorization()
			} else if hasWhenInUseKey == true {
				manager.requestWhenInUseAuthorization()
			} else {
				// You've forgot something essential
				assert(false, "To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.")
			}
		}
		
		// Location Update
		if hasActiveRequests([RequestType.ContinuousLocationUpdate,RequestType.SingleShotLocation]) == true {
			let requiredAccuracy = self.highestRequiredAccuracy()
			if requiredAccuracy != manager.desiredAccuracy {
				manager.stopUpdatingLocation()
				manager.desiredAccuracy = requiredAccuracy
			}
			manager.startUpdatingLocation()
		} else {
			manager.stopUpdatingLocation()
		}
		// Significant Location Changes
		if hasActiveRequests([RequestType.ContinuousSignificantLocation]) == true {
			manager.startMonitoringSignificantLocationChanges()
		} else {
			manager.stopMonitoringSignificantLocationChanges()
		}
		// Beacon/Region monitor is turned off automatically on completeRequest()
		let beaconRegions = self.activeRequests([RequestType.BeaconRegionProximity])
		for beaconRegion in beaconRegions {
			manager.startRangingBeaconsInRegion(beaconRegion.beaconReg!)
		}
	}
	
	/**
	Return true if a request into the pool is of type described by the list of types passed
	
	- parameter list: allowed types
	
	- returns: true if at least one request with one the specified type is running
	*/
	private func hasActiveRequests(list: [RequestType]) -> Bool! {
		for request in requests {
			let idx = list.indexOf(request.type)
			if idx != nil {
				return true
			}
		}
		return false
	}
	
	/**
	Return the list of all request of a certain type
	
	- parameter list: list of types to filter
	
	- returns: output list with filtered active requests
	*/
	private func activeRequests(list: [RequestType]) -> [SwiftLocationRequest] {
		var filteredList : [SwiftLocationRequest] = []
		for request in requests {
			let idx = list.indexOf(request.type)
			if idx != nil {
				filteredList.append(request)
			}
		}
		return filteredList
	}
	
	/**
	In case of an error we want to expire all queued notifications
	
	- parameter error: error to notify
	*/
	private func expireAllRequests(error: NSError?, types: [RequestType]?) {
		for request in requests {
			let canMark = (types == nil ? true : (types!.indexOf(request.type) != nil))
			if canMark == true {
				request.markAsCancelled(error)
			}
		}
	}
	
	//MARK: [Private] Location Manager Delegate
	
	public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		locationsReceived(locations)
	}
	
	private func locationsReceived(locations: [AnyObject]!) {
		if let location = locations.last as? CLLocation {
			for request in requests {
				if request.isAcceptable(location) == true {
					completeRequest(request, object: location, error: nil)
				}
			}
		}
	}
	
	public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		let expiredTypes = [RequestType.ContinuousLocationUpdate,
							RequestType.ContinuousSignificantLocation,
							RequestType.SingleShotLocation,
							RequestType.ContinuousHeadingUpdate,
							RequestType.RegionMonitor]
		expireAllRequests(error, types: expiredTypes)
	}
	
	public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == CLAuthorizationStatus.Denied || status == CLAuthorizationStatus.Restricted {
			// Clear out any pending location requests (which will execute the blocks with a status that reflects
			// the unavailability of location services) since we now no longer have location services permissions
			let err = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Location services denied/restricted by parental control"])
			locationManager(manager, didFailWithError: err)
		} else if status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse {
			for request in requests {
				request.startTimeout(nil)
			}
			updateLocationManagerStatus()
		} else if status == CLAuthorizationStatus.NotDetermined {
			print("not")
		}
	}
	
	public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
		let request = requestForRegion(region)
		request?.onRegionEnter?(region: region)
	}
	
	public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
		let request = requestForRegion(region)
		request?.onRegionExit?(region: region)
	}
	
	public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
		for request in requests {
			if request.beaconReg == region {
				request.onRangingBeaconEvent?(beacons: beacons)
			}
		}
	}
	
	public func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
		let expiredTypes = [RequestType.BeaconRegionProximity]
		expireAllRequests(error, types: expiredTypes)
	}

}

/**
This is the request type

- SingleShotLocation:            Single location request with desidered accuracy level
- SingleShotIPLocation:          Single location request with IP-based location search (used automatically with accuracy set to Country)
- ContinuousLocationUpdate:      Continous location update
- ContinuousSignificantLocation: Significant location update requests
- ContinuousHeadingUpdate:       Continous heading update requests
- RegionMonitor:                 Monitor specified region
- BeaconRegionProximity:         Search for beacon services nearby the device
*/
enum RequestType {
	case SingleShotLocation
	case SingleShotIPLocation
	case ContinuousLocationUpdate
	case ContinuousSignificantLocation
	case ContinuousHeadingUpdate
	case RegionMonitor
	case BeaconRegionProximity
}

private extension CLLocation {
	func accuracyOfLocation() -> Accuracy! {
		let timeSinceUpdate = fabs( self.timestamp.timeIntervalSinceNow )
		let horizontalAccuracy = self.horizontalAccuracy
		
		if horizontalAccuracy <= Accuracy.Room.accuracyThreshold() &&
			timeSinceUpdate <= Accuracy.Room.timeThreshold() {
				return Accuracy.Room
				
		} else if horizontalAccuracy <= Accuracy.House.accuracyThreshold() &&
			timeSinceUpdate <= Accuracy.House.timeThreshold() {
				return Accuracy.House
				
		} else if horizontalAccuracy <= Accuracy.Block.accuracyThreshold() &&
			timeSinceUpdate <= Accuracy.Block.timeThreshold() {
				return Accuracy.Block
				
		} else if horizontalAccuracy <= Accuracy.Neighborhood.accuracyThreshold() &&
			timeSinceUpdate <= Accuracy.Neighborhood.timeThreshold() {
				return Accuracy.Neighborhood
				
		} else if horizontalAccuracy <= Accuracy.City.accuracyThreshold() &&
			timeSinceUpdate <= Accuracy.City.timeThreshold() {
				return Accuracy.City
		} else {
			return Accuracy.None
		}
	}
}

//MARK: ===== [PRIVATE] SwiftLocationRequest Class =====

var requestNextID: RequestIDType = 0

/// This is the class which represent a single request.
/// Usually you should not interact with it. The only action you can perform on it is to call the cancel method to abort a running request.
public class SwiftLocationRequest: NSObject {
	private(set) var type: RequestType
	private(set) var ID: RequestIDType
	private(set) var isCancelled: Bool!
	var onTimeOut: onTimeoutReached?
	
	// location related handlers
	private var onSuccess: onSuccessLocate?
	private var onError: onErrorLocate?
	
	// region/beacon related handlers
	private var region: CLRegion?
	private var beaconReg: CLBeaconRegion?
	private var onRegionEnter: onRegionEvent?
	private var onRegionExit: onRegionEvent?
	private var onRangingBeaconEvent: onRangingBacon?
	
	
	var desideredAccuracy: Accuracy!
	private var timeoutTimer: NSTimer?
	private var timeoutInterval: NSTimeInterval
	private var hasTimeout: Bool!
	
	//MARK: Init - Private Methods
	private init(requestType: RequestType, accuracy: Accuracy,timeout: NSTimeInterval, success: onSuccessLocate, fail: onErrorLocate?) {
		type = requestType
		requestNextID++
		ID = requestNextID
		isCancelled = false
		onSuccess = success
		onError = fail
		desideredAccuracy = accuracy
		timeoutInterval = timeout
		hasTimeout = false
		super.init()
		if SwiftLocation.state == ServiceStatus.Available {
			self.startTimeout(nil)
		}
	}
	
	private init(region: CLRegion!, onEnter: onRegionEvent?, onExit: onRegionEvent?) {
		type = RequestType.RegionMonitor
		requestNextID++
		ID = requestNextID
		isCancelled = false
		onRegionEnter = onEnter
		onRegionExit = onExit
		desideredAccuracy = Accuracy.None
		timeoutInterval = 0
		hasTimeout = false
		super.init()
	}
	
	private init(beaconRegion: CLBeaconRegion!, onRanging: onRangingBacon?) {
		type = RequestType.BeaconRegionProximity
		requestNextID++
		ID = requestNextID
		isCancelled = false
		onRangingBeaconEvent = onRanging
		desideredAccuracy = Accuracy.None
		timeoutInterval = 0
		hasTimeout = false
		beaconReg = beaconRegion
		super.init()
	}
	
	//MARK: Public Methods
	
	/**
	Cancel method abort a running request
	*/
	private func markAsCancelled(error: NSError?) {
		isCancelled = true
		stopTimeout()
		SwiftLocation.shared.completeRequest(self, object: nil, error: error)
	}
	
	//MARK: Private Methods
	private func isAcceptable(location: CLLocation) -> Bool! {
		if isCancelled == true {
			return false
		}
		if desideredAccuracy == Accuracy.None {
			return true
		}
		let locAccuracy: Accuracy! = location.accuracyOfLocation()
		let valid = (locAccuracy.rawValue >= desideredAccuracy.rawValue)
		return valid
	}
	
	private func startTimeout(forceValue: NSTimeInterval?) {
		if hasTimeout == false && timeoutInterval > 0 {
			let value = (forceValue != nil ? forceValue! : timeoutInterval)
			timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(value, target: self, selector: "timeoutReached", userInfo: nil, repeats: false)
		}
	}
	
	private func stopTimeout() {
		timeoutTimer?.invalidate()
		timeoutTimer = nil
	}
	
	public func timeoutReached() {
		let additionalTime: NSTimeInterval? = onTimeOut?()
		if additionalTime == nil {
			timeoutTimer?.invalidate()
			timeoutTimer = nil
			hasTimeout = true
			isCancelled = false
			let error = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Timeout reached"])
			SwiftLocation.shared.completeRequest(self, object: nil, error: error)
		} else {
			hasTimeout = false
			startTimeout(additionalTime!)
		}
	}
}

//MARK: ===== [PRIVATE] SwiftLocationParser Class =====

// Portions of this class are part of the LocationManager mady by varshylmobile (AddressParser class):
// (Made by https://github.com/varshylmobile/LocationManager)

private class SwiftLocationParser: NSObject {
	private var latitude = NSString()
	private var longitude  = NSString()
	private var streetNumber = NSString()
	private var route = NSString()
	private var locality = NSString()
	private var subLocality = NSString()
	private var formattedAddress = NSString()
	private var administrativeArea = NSString()
	private var administrativeAreaCode = NSString()
	private var subAdministrativeArea = NSString()
	private var postalCode = NSString()
	private var country = NSString()
	private var subThoroughfare = NSString()
	private var thoroughfare = NSString()
	private var ISOcountryCode = NSString()
	private var state = NSString()
	
	override init() {
		super.init()
	}
	
	private func parseIPLocationData(JSON: NSDictionary) -> Bool {
		let status = JSON["status"] as? String
		if status != "success" {
			return false
		}
		self.country = JSON["country"] as! NSString
		self.ISOcountryCode = JSON["countryCode"] as! NSString
		if let lat = JSON["lat"] as? NSNumber, lon = JSON["lon"] as? NSNumber {
			self.longitude = lat.description
			self.latitude = lon.description
		}
		self.postalCode = JSON["zip"] as! NSString
		return true
	}
	
	private func parseAppleLocationData(placemark:CLPlacemark) {
		let addressLines = placemark.addressDictionary?["FormattedAddressLines"] as! NSArray
		
		//self.streetNumber = placemark.subThoroughfare ? placemark.subThoroughfare : ""
		self.streetNumber = placemark.thoroughfare ?? ""
		self.locality = placemark.locality ?? ""
		self.postalCode = placemark.postalCode ?? ""
		self.subLocality = placemark.subLocality ?? ""
		self.administrativeArea = placemark.administrativeArea ?? ""
		self.country = placemark.country ?? ""
        if let location = placemark.location {
            self.longitude = location.coordinate.longitude.description;
            self.latitude = location.coordinate.latitude.description
        }
		if addressLines.count>0 {
			self.formattedAddress = addressLines.componentsJoinedByString(", ")
		} else {
			self.formattedAddress = ""
		}
	}
	
	private func parseGoogleLocationData(resultDict:NSDictionary) {
		let locationDict = (resultDict.valueForKey("results") as! NSArray).firstObject as! NSDictionary
		let formattedAddrs = locationDict.objectForKey("formatted_address") as! NSString
		
		let geometry = locationDict.objectForKey("geometry") as! NSDictionary
		let location = geometry.objectForKey("location") as! NSDictionary
		let lat = location.objectForKey("lat") as! Double
		let lng = location.objectForKey("lng") as! Double
		
		self.latitude = lat.description
		self.longitude = lng.description
		
		let addressComponents = locationDict.objectForKey("address_components") as! NSArray
		self.subThoroughfare = component("street_number", inArray: addressComponents, ofType: "long_name")
		self.thoroughfare = component("route", inArray: addressComponents, ofType: "long_name")
		self.streetNumber = self.subThoroughfare
		self.locality = component("locality", inArray: addressComponents, ofType: "long_name")
		self.postalCode = component("postal_code", inArray: addressComponents, ofType: "long_name")
		self.route = component("route", inArray: addressComponents, ofType: "long_name")
		self.subLocality = component("subLocality", inArray: addressComponents, ofType: "long_name")
		self.administrativeArea = component("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
		self.administrativeAreaCode = component("administrative_area_level_1", inArray: addressComponents, ofType: "short_name")
		self.subAdministrativeArea = component("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
		self.country =  component("country", inArray: addressComponents, ofType: "long_name")
		self.ISOcountryCode =  component("country", inArray: addressComponents, ofType: "short_name")
		self.formattedAddress = formattedAddrs;
	}
	
	private func getPlacemark() -> CLPlacemark {
        var addressDict = [String:AnyObject]()
		let formattedAddressArray = self.formattedAddress.componentsSeparatedByString(", ") as Array
		
		let kSubAdministrativeArea = "SubAdministrativeArea"
		let kSubLocality           = "SubLocality"
		let kState                 = "State"
		let kStreet                = "Street"
		let kThoroughfare          = "Thoroughfare"
		let kFormattedAddressLines = "FormattedAddressLines"
		let kSubThoroughfare       = "SubThoroughfare"
		let kPostCodeExtension     = "PostCodeExtension"
		let kCity                  = "City"
		let kZIP                   = "ZIP"
		let kCountry               = "Country"
		let kCountryCode           = "CountryCode"
		
        addressDict[kSubAdministrativeArea] = self.subAdministrativeArea
        addressDict[kSubLocality] = self.subLocality
        addressDict[kState] = self.administrativeAreaCode
        addressDict[kStreet] = formattedAddressArray.first! as NSString
        addressDict[kThoroughfare] = self.thoroughfare
        addressDict[kFormattedAddressLines] = formattedAddressArray
        addressDict[kSubThoroughfare] = self.subThoroughfare
        addressDict[kPostCodeExtension] = ""
        addressDict[kCity] = self.locality
        addressDict[kZIP] = self.postalCode
		addressDict[kCountry] = self.country
        addressDict[kCountryCode] = self.ISOcountryCode
		
		let lat = self.latitude.doubleValue
		let lng = self.longitude.doubleValue
		let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
		
		let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
		return (placemark as CLPlacemark)
	}
	
	private func component(component:NSString,inArray:NSArray,ofType:NSString) -> NSString {
		let index:NSInteger = inArray.indexOfObjectPassingTest { (obj, idx, stop) -> Bool in
			
			let objDict:NSDictionary = obj as! NSDictionary
			let types:NSArray = objDict.objectForKey("types") as! NSArray
			let type = types.firstObject as! NSString
			return type.isEqualToString(component as String)
		}
		
		if index == NSNotFound {
			return ""
		}
		
		if index >= inArray.count {
			return ""
		}
		
		let type = ((inArray.objectAtIndex(index) as! NSDictionary).valueForKey(ofType as String)!) as! NSString
		
		if type.length > 0 {
			
			return type
		}
		return ""
	}
}