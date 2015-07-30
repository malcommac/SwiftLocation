//
//  SwiftLocation.swift
//  SwiftLocations
//
//  Created by daniele on 28/07/15.
//  Copyright (c) 2015 danielemargutti. All rights reserved.
//

import UIKit
import CoreLocation

var requestNextID: Int = 0

//MARK: SwiftLocation

class SwiftLocation: NSObject, CLLocationManagerDelegate {
	static let shared = SwiftLocation()
	private var manager: CLLocationManager
	private var requests: [SwiftLocationRequest]!
	private let blocksDispatchQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
	
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
				default:
					return .Undetermined
				}
			}
		}
	}
	
	override private init() {
		requests = []
		manager = CLLocationManager()
		super.init()
		manager.delegate = self
	}
	
	//MARK: PUBLIC METHODS
	
	/**
	This method submits the specified location data to the geocoding server asynchronously and returns.
	
	:param: coordinates
	:param: onSuccess on success handler with CLPlacemarks objects
	:param: onFail    on error handler with error description
	*/
	func reverseCoordinates(coordinates: CLLocationCoordinate2D!, onSuccess: ((places: [AnyObject]?)->Void)?, onFail: ((error: NSError?)->Void)? ) {
		let geocoder = CLGeocoder()
		let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
		geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
			if error != nil {
				onFail?(error: error)
			} else {
				onSuccess?(places: placemarks)
			}
		})
	}
	
	/**
	Submits a forward-geocoding request using the specified string and optional region information.
	
	:param: address   A string describing the location you want to look up. For example, you could specify the string “1 Infinite Loop, Cupertino, CA” to locate Apple headquarters.
	:param: region    (Optional) A geographical region to use as a hint when looking up the specified address.
	:param: onSuccess on success handler
	:param: onFail    on error handler
	*/
	func reverseAddress(address: String!, region: CLRegion?, onSuccess: ((place: [AnyObject]?)->Void)?, onFail: ((error: NSError?)->Void)? ) {
		let geocoder = CLGeocoder()
		if region != nil {
			geocoder.geocodeAddressString(address, inRegion: region, completionHandler: { (placemarks, error) in
				if error != nil {
					onFail?(error: error)
				} else {
					onSuccess?(place: placemarks)
				}
			})
		} else {
			geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
				if error != nil {
					onFail?(error: error)
				} else {
					onSuccess?(place: placemarks)
				}
			})
		}
	}
	
	/**
	Submits a forward-geocoding request using the specified address dictionary.
	
	:param: dictionary An Address Book dictionary containing information about the address to look up.
	:param: onSuccess on success handler
	:param: onFail    on error handler
	*/
	func reverseAddress(dictionary: [NSObject : AnyObject], onSuccess: ((place: [AnyObject]?)->Void)?, onFail: ((error: NSError?)->Void)?) {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressDictionary(dictionary, completionHandler: { (placemarks, error) in
			if error != nil {
				onFail?(error: error)
			} else {
				onSuccess?(place: placemarks)
			}
		})
	}
	
	/**
	Get the current location from location manager with given accuracy
	
	:param: accuracy  minimum accuracy value to accept (country accuracy uses IP based location, not the CoreLocationManager, and it does not require user authorization)
	:param: timeout   search timeout. When expired, method return directly onFail
	:param: onSuccess handler called when location is found
	:param: onFail    handler called when location manager fails due to an error
	
	:returns: return an object to manage the request itself
	*/
	func currentLocation(accuracy: Accuracy, timeout: NSTimeInterval, onSuccess: onSuccessLocate, onFail: onErrorLocate) -> SwiftLocationRequest {
		if accuracy == Accuracy.Country {
			let newRequest = SwiftLocationRequest(requestType: RequestType.SingleShotIPLocation, accuracy:accuracy, timeout: timeout, success: onSuccess, fail: onFail)
			locateByIP(newRequest, refresh: false, timeout: timeout, onEnd: { (place, error) -> Void in
				if error != nil {
					onFail(error: error)
				} else {
					onSuccess(location: place)
				}
			})
			addRequest(newRequest)
			return newRequest
		} else {
			let newRequest = SwiftLocationRequest(requestType: RequestType.SingleShotLocation, accuracy:accuracy, timeout: timeout, success: onSuccess, fail: onFail)
			addRequest(newRequest)
			return newRequest
		}
	}
	
	/**
	This method continously report found locations with desidered or better accuracy. You need to stop it manually by calling cancel() method into the request.
	
	:param: accuracy  minimum accuracy value to accept (country accuracy is not allowed)
	:param: onSuccess handler called each time a new position is found
	:param: onFail    handler called when location manager fail (the request itself is aborted automatically)
	
	:returns: return an object to manage the request itself
	*/
	func continuousLocation(accuracy: Accuracy, onSuccess: onSuccessLocate, onFail: onErrorLocate) -> SwiftLocationRequest {
		let newRequest = SwiftLocationRequest(requestType: RequestType.ContinuousLocationUpdate, accuracy:accuracy, timeout: 0, success: onSuccess, fail: onFail)
		addRequest(newRequest)
		return newRequest
	}
	
	/**
	This method continously return only significant location changes. This capability provides tremendous power savings for apps that want to track a user’s approximate location and do not need highly accurate position information. You need to stop it manually by calling cancel() method into the request.
	
	:param: onSuccess handler called each time a new position is found
	:param: onFail    handler called when location manager fail (the request itself is aborted automatically)
	
	:returns: return an object to manage the request itself
	*/
	func significantLocation(onSuccess: onSuccessLocate, onFail: onErrorLocate) -> SwiftLocationRequest {
		let newRequest = SwiftLocationRequest(requestType: RequestType.ContinuousSignificantLocation, accuracy:Accuracy.None, timeout: 0, success: onSuccess, fail: onFail)
		addRequest(newRequest)
		return newRequest
	}
	
	/**
	Start monitoring specified region by reporting when users move in/out from it. You must call this method once for each region you want to monitor. You need to stop it manually by calling cancel() method into the request.
	
	:param: region  region to monitor
	:param: onEnter handler called when user move into the region
	:param: onExit  handler called when user move out from the region
	
	:returns: return an object to manage the request itself
	*/
	func monitorRegion(region: CLRegion!, onEnter: onRegionEvent?, onExit: onRegionEvent?) -> SwiftLocationRequest? {
		let isAvailable = CLLocationManager.isMonitoringAvailableForClass(CLRegion.self)
		if isAvailable == true {
			let request = SwiftLocationRequest(region: region, onEnter: onEnter, onExit: onExit)
			manager.startMonitoringForRegion(region as CLRegion)
			return request
		}
		return nil
	}
	
	/**
	Starts the delivery of notifications for beacons in the specified region.
	
	:param: region    region to monitor
	:param: onRanging handler called every time one or more beacon are in range, ordered by distance (closest is the first one)
	
	:returns: return an object to manage the request itself
	*/
	func monitorBeaconsInRegion(region: CLBeaconRegion!, onRanging: onRangingBacon? ) -> SwiftLocationRequest? {
		let isAvailable = CLLocationManager.isRangingAvailable()
		if isAvailable == true {
			let request = SwiftLocationRequest(beaconRegion: region, onRanging: onRanging)
			manager.startRangingBeaconsInRegion(region)
			return request
		}
		return nil
	}
	
	//MARK: PRIVATE METHODS
	
	private func locateByIP(request: SwiftLocationRequest, refresh: Bool = false, timeout: NSTimeInterval, onEnd: ( (place: SwiftLocationPlace?, error: NSError?) -> Void)? ) {
		let policy = (refresh == false ? NSURLRequestCachePolicy.ReturnCacheDataElseLoad : NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData)
		let URLRequest = NSURLRequest(URL: NSURL(string: "http://ip-api.com/json")!, cachePolicy: policy, timeoutInterval: timeout)
		NSURLConnection.sendAsynchronousRequest(URLRequest, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
			if request.isCancelled == true {
				onEnd?(place: nil, error: nil)
				return
			}
			if let data = data as NSData? {
				var jsonError: NSError?
				if let resultDict = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? NSDictionary {
					onEnd?(place: SwiftLocationPlace(JSON: resultDict), error:nil)
				} else {
					onEnd?(place: nil, error: jsonError)
				}
			} else {
				onEnd?(place: nil, error: error)
			}
		}
	}
	
	//MARK: HELPER METHODS
	
	private func addRequest(request: SwiftLocationRequest!) {
		dispatch_sync(blocksDispatchQueue) {
			self.requests.append(request)
			self.updateLocationManagerStatus()
		}
	}
	
	private func completeRequest(request: SwiftLocationRequest!, location: SwiftLocationPlace?, error: NSError?) {
		if request.type == RequestType.RegionMonitor {
			manager.stopMonitoringForRegion(request.region!)
		} else if (request.type == RequestType.BeaconRegionProximity) {
			manager.stopRangingBeaconsInRegion(request.beaconReg!)
		}
		
		dispatch_sync(blocksDispatchQueue) {
			var idx = 0
			for cRequest in self.requests {
				if cRequest.ID == request.ID {
					cRequest.stopTimeout()
					if cRequest.type != RequestType.RegionMonitor {
						if error != nil {
							cRequest.onError?(error: error)
						} else {
							cRequest.onSuccess?(location: location)
						}
					}
					if cRequest.type != RequestType.ContinuousLocationUpdate {
						self.requests.removeAtIndex(idx)
					}
				}
				idx++
			}
			self.updateLocationManagerStatus()
		}
	}
	
	private func updateLocationManagerStatus() {
		if requests.count > 0 {
			let hasAlwaysKey = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") != nil)
			let hasWhenInUseKey = (NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription") != nil)
			if hasAlwaysKey == true {
				manager.requestAlwaysAuthorization()
			} else if hasWhenInUseKey == true {
				manager.requestWhenInUseAuthorization()
			} else {
				assert(false, "To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.")
			}
		}
		
		if hasActiveRequests([RequestType.ContinuousLocationUpdate,RequestType.SingleShotLocation]) == true {
			manager.startUpdatingLocation()
		} else {
			manager.stopUpdatingLocation()
		}
		if hasActiveRequests([RequestType.ContinuousSignificantLocation]) == true {
			manager.startMonitoringSignificantLocationChanges()
		} else {
			manager.stopMonitoringSignificantLocationChanges()
		}
	}
	
	private func hasActiveRequests(list: [RequestType]) -> Bool! {
		for request in requests {
			let idx = find(list, request.type)
			if idx != nil {
				return true
			}
		}
		return false
	}
	
	//MARK: LOCATION MANAGER DELEGATE
	
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		var place: SwiftLocationPlace?
		if let location = locations.last as? CLLocation {
			let acc = location.accuracyOfLocation()
			for request in requests {
				if request.isAcceptable(location) == true {
					if place == nil {
						place = SwiftLocationPlace(currentLocation: location)
					}
					completeRequest(request, location: place, error: nil)
				}
			}
		}
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		expireAllRequests(error)
	}
	
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == CLAuthorizationStatus.Denied || status == CLAuthorizationStatus.Restricted {
			// Clear out any pending location requests (which will execute the blocks with a status that reflects
			// the unavailability of location services) since we now no longer have location services permissions
			let err = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Location services denied/restricted by parental control"])
			expireAllRequests(err)
		} else if status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse {
			for request in requests {
				request.startTimeout(nil)
			}
		}
	}
	
	func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
		let request = requestForRegion(region)
		request?.onRegionEnter?(region: region)
	}
	
	func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
		let request = requestForRegion(region)
		request?.onRegionExit?(region: region)
	}
	
	private func requestForRegion(region: CLRegion!) -> SwiftLocationRequest? {
		for request in requests {
			if request.type == RequestType.RegionMonitor && request.region == region {
				return request
			}
		}
		return nil
	}
	
	func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
		for request in requests {
			if request.beaconReg == region {
				request.onRangingBeaconEvent?(regions: beacons)
			}
		}
	}
	
	private func expireAllRequests(error: NSError?) {
		for request in requests {
			completeRequest(request, location: nil, error: error)
		}
	}
}

//MARK: SwiftLocationPlace

class SwiftLocationPlace {
	private(set) var location:		CLLocation?
	private(set) var accuracy:		Accuracy?
	private(set) var country:		String?
	private(set) var countryCode:	String?
	private(set) var zipCode:		String?
	private(set) var name:			String?
	private(set) var timezone:		NSTimeZone?
	private var placemark:		CLPlacemark?
	
	init(currentLocation: CLLocation) {
		location = currentLocation
	}
	
	init?(JSON: NSDictionary) {
		let status = JSON["status"] as? String
		if status != "success" {
			return nil
		}
		accuracy = Accuracy.Country
		country = JSON["country"] as? String
		countryCode = JSON["countryCode"] as? String
		if let lat = JSON["lat"] as? NSNumber, lon = JSON["lon"] as? NSNumber {
			location = CLLocation(latitude: CLLocationDegrees(lat.doubleValue), longitude:  CLLocationDegrees(lon.doubleValue))
		}
		if let timezoneStr = JSON["timezone"] as? String {
			timezone = NSTimeZone(name: timezoneStr)
		}
		zipCode = JSON["zip"] as? String
	}
	
	func placemark(onSuccess: ((place: CLPlacemark?) -> Void)?, onFail: ((error: NSError?) -> Void)? ) {
		if placemark != nil {
			onSuccess?(place: placemark!)
		} else {
			let geocoder = CLGeocoder()
			geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
				if error != nil {
					onFail?(error: error)
				} else {
					self.placemark = placemarks.last as? CLPlacemark
					onSuccess?(place: self.placemark)
				}
			})
		}
	}
}

enum Accuracy:Int, Printable {
	case None = 0
	case Country = 1
	case City = 2
	case Neighborhood = 3
	case Block = 4
	case House = 5
	case Room = 6
	
	var description: String {
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
			default:
				return "Unknown"
			}
		}
	}
	
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

enum RequestType {
	case SingleShotLocation
	case SingleShotIPLocation
	case ContinuousLocationUpdate
	case ContinuousSignificantLocation
	case ContinuousHeadingUpdate
	case RegionMonitor
	case BeaconRegionProximity
}

typealias onSuccessLocate = ( (location: SwiftLocationPlace?) -> Void)
typealias onErrorLocate = ( (error: NSError?) -> Void )
typealias onTimeoutReached = ( Void -> (NSTimeInterval?) )
typealias onRegionEvent = ( (region: AnyObject?) -> Void)
typealias onRangingBacon = ( (regions: [AnyObject]) -> Void)

extension CLLocation {
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

class SwiftLocationRequest: NSObject {
	private(set) var type: RequestType
	private(set) var ID: Int
	private(set) var isCancelled: Bool!
	var onTimeOut: onTimeoutReached?
	private var onSuccess: onSuccessLocate?
	private var onError: onErrorLocate?
	
	private var region: CLRegion?
	private var beaconReg: CLBeaconRegion?
	private var onRegionEnter: onRegionEvent?
	private var onRegionExit: onRegionEvent?
	private var onRangingBeaconEvent: onRangingBacon?
	
	var desideredAccuracy: Accuracy!
	private var timeoutTimer: NSTimer?
	private var timeoutInterval: NSTimeInterval
	private var hasTimeout: Bool!
	
	init(requestType: RequestType, accuracy: Accuracy,timeout: NSTimeInterval, success: onSuccessLocate, fail: onErrorLocate?) {
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
	
	init(region: CLRegion!, onEnter: onRegionEvent?, onExit: onRegionEvent?) {
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
	
	init(beaconRegion: CLBeaconRegion!, onRanging: onRangingBacon?) {
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
	
	func cancel() {
		isCancelled = true
		stopTimeout()
		SwiftLocation.shared.completeRequest(self, location: nil, error: nil)
	}
	
	func isAcceptable(location: CLLocation) -> Bool! {
		if isCancelled == true {
			return false
		}
		if desideredAccuracy == Accuracy.None {
			return true
		}
		let locAccuracy: Accuracy! = location.accuracyOfLocation()
		let valid = (locAccuracy.rawValue > desideredAccuracy.rawValue)
		return valid
	}
	
	func startTimeout(forceValue: NSTimeInterval?) {
		if hasTimeout == false && timeoutInterval > 0 {
			let value = (forceValue != nil ? forceValue! : timeoutInterval)
			timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(value, target: self, selector: "timeoutReached", userInfo: nil, repeats: false)
		}
	}
	
	func stopTimeout() {
		timeoutTimer?.invalidate()
		timeoutTimer = nil
	}
	
	func timeoutReached() {
		var additionalTime: NSTimeInterval? = onTimeOut?()
		if additionalTime == nil {
			timeoutTimer?.invalidate()
			timeoutTimer = nil
			hasTimeout = true
			isCancelled = false
			let error = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "Timeout reached"])
			SwiftLocation.shared.completeRequest(self, location: nil, error: error)
		} else {
			hasTimeout = false
			startTimeout(additionalTime!)
		}
	}
}

enum ServiceStatus :Int {
	case Available
	case Undetermined
	case Denied
	case Restricted
	case Disabled
}