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

let DefaultTimeout: TimeInterval = 30.0

public let Location:LocationManager = LocationManager.shared

public class LocationManager: NSObject, CLLocationManagerDelegate {
	//MARK: Public Variables
	public private(set) var lastLocation: CLLocation?

		/// Shared instance of the location manager
	internal static let shared = LocationManager()
	
	/// You can specify a valid Google API Key if you want to use Google geocoding services without a strict quota
	public var googleAPIKey: String?
	
		/// A Boolean value indicating whether the app wants to receive location updates when suspended. By default it's false.
		/// See .allowsBackgroundLocationUpdates of CLLocationManager for a detailed description of this var.
	public var allowsBackgroundEvents: Bool = false {
		didSet {
			if #available(iOS 9.0, *) {
				if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? NSArray {
					if backgroundModes.contains("location") {
						self.manager.allowsBackgroundLocationUpdates = allowsBackgroundEvents
					} else {
						print("You must provide location in UIBackgroundModes of Info.plist in order to use .allowsBackgroundEvents")
					}
				}
			}
		}
	}
	
		/// A Boolean value indicating whether the location manager object may pause location updates.
		/// When this property is set to YES, the location manager pauses updates (and powers down the appropriate hardware)
		/// at times when the location data is unlikely to change.
		/// You can observe this event by setting the appropriate handler on .onPause() method of the request.
	public var pausesLocationUpdatesWhenPossible: Bool = true {
		didSet {
			self.manager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesWhenPossible
		}
	}
	
		/// When computing heading values, the location manager assumes that the top of the device in portrait mode
		/// represents due north (0 degrees) by default. By default this value is set to .FaceUp.
		/// The original reference point is retained, changing this value has no effect on orientation reference point.
		/// Changing the value in this property affects only those heading values reported after the change is made.
	public var headingOrientation: CLDeviceOrientation = .faceUp {
		didSet {
			self.updateHeadingService()
		}
	}
	
	//MARK: Private Variables
	private let manager: CLLocationManager
		/// The list of all requests to observe current location changes
	private(set) var locationObservers: [LocationRequest] = []
		/// The list of all requests to observe device's heading changes
	private(set) var headingObservers: [HeadingRequest] = []
		/// THe list of all requests to oberver significant places visits
	private(set) var visitsObservers: [VisitRequest] = []

	//MARK: Init
	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.manager.delegate = self
	}

	//MARK: PUBLIC METHODS
	
	/**
	Retrive current device location
	
	- parameter accuracy:  accuracy you want to achieve. This value is mandatory; depending on your position you may not achieve desidered accuracy. If not achieved function will catch error by sending best achieved location.
	- parameter frequency: frequency of update. By default is OneShot (once found request is fullfilled and stopped automatically). You can receive updates countinously or at specified time interval. See UpdateFrequency for more detailed info. Frequency is .OneShot when accuracy is set to .IPScan.
	- parameter timeout:   timeout timer; if desidered location was not found at the end of timeout request fail and last valid location is reported to the user
	- parameter onSuccess: handler called when desidered location was achieved successfully
	- parameter onError:   handler called when desidered location cannot be achieved. Best location found will be reported.
	
	- returns: request instance. Use it to pause, resume or stop request
	*/
	public func getLocation(withAccuracy accuracy: Accuracy, frequency: UpdateFrequency = .oneShot, timeout: TimeInterval = DefaultTimeout, onSuccess: LocationHandlerSuccess, onError: LocationHandlerError) -> Request {
		
		if accuracy == .ipScan {
			return self.getLocationViaIPScan(timeout, onSuccess: onSuccess, onError: onError)
		} else {
			let request = LocationRequest(withAccuracy: accuracy, andFrequency: frequency)
			request.timeout = timeout
			let _ = request.onSuccess(onSuccess)
			let _ = request.onError(onError)
			request.start()
			return request
		}
	}
	
	
	/**
	Receive events from device's heading changes.
	
	- parameter frequency:         Specify frequency of the update
	- parameter accuracy:          Specify accuracy (in degree) of the updates
	- parameter allowsCalibration: true if standard iOS calibration screen can show if required
	- parameter update:            handler called when a new heading is generated
	- parameter error:             handler called when an error has occurred. Request is rejected and stopped.
	
	- returns: request istance
	*/
	public func getHeading(_ frequency: HeadingFrequency = .continuous(interval: nil), accuracy: CLLocationDirection, allowsCalibration: Bool = true, didUpdate update: HeadingHandlerSuccess, onError error: HeadingHandlerError) -> Request {
		let request = HeadingRequest(withFrequency: frequency, accuracy: accuracy, allowsCalibration: allowsCalibration)
		request.onReceiveUpdates = update
		request.onError = error
		request.start()
		return request
	}
	

	/**
	Calling this method begins the delivery of visit-related events to your app.
	Enabling visit events for one location manager enables visit events for all other location manager objects in your app.
	If your app is terminated while this service is active, the system relaunches your app when new visit events are ready to be delivered.
	
	- parameter handler: handler called when a new visit is intercepted
	
	- returns: the request object which represent the current observer. You can use it to pause/resume or stop the observer itself.
	*/
	public func getInterestingPlaces(onDidVisit handler: VisitHandler?) -> Request {
		let request = VisitRequest(onDidVisit: handler)
		let _ = self.addVisitRequest(request)
		return request
	}
	
	//MARK: [Public Methods] Reverse Address/Location
	
	/**
	This function make a reverse geocoding from an address string to a valid geographic place (returned as CLPlacemark instance).
	You can use both Apple's own service or Google service to get this value.
	
	- parameter service:  service to use, If not passed .Apple is used
	- parameter address:  address string to reverse
	- parameter sHandler: handler called when location reverse operation was completed successfully. It contains a valid CLPlacemark instance.
	- parameter fHandler: handler called when the operation fails due to an error.
	*/
	public func reverse(address: String, using service: ReverseService = .apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
		switch service {
		case .apple:
			return self.reverse_apple(address: address, onSuccess: onSuccess, onError: onError)
		case .google:
			return self.reverse_google(address: address, onSuccess: onSuccess, onError: onError)
		}
	}
	
	/**
	This function make a geocoding request returning a valid geographic place (returned as CLPlacemark instance) from a passed pair of
	coordinates.
	
	- parameter service:     service to use. If not passed .Google is used
	- parameter coordinates: coordinates to search
	- parameter sHandler:    handler called when location geocoding succeded and a valid CLPlacemark is returned
	- parameter fHandler:    handler called when location geocoding fails due to an error
	*/
	
	public func reverse(coordinates: CLLocationCoordinate2D, using service:ReverseService = .apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
		let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
		return self.reverse(location: location, using: service, onSuccess: onSuccess, onError: onError)
	}
	
	/**
	This function make a geocoding request returning a valid geographic place (returned as CLPlacemark instance) from a passed location object.
	
	- parameter service:  service to use. If not passed .Google is used
	- parameter location: location to search
	- parameter sHandler:    handler called when location geocoding succeded and a valid CLPlacemark is returned
	- parameter fHandler:    handler called when location geocoding fails due to an error
	*/
	public func reverse(location: CLLocation, using service :ReverseService = .apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
		switch service {
		case .apple:
			return self.reverse_location_apple(location, onSuccess: onSuccess, onError: onError)
		case .google:
			return self.reverse_location_google(location, onSuccess: onSuccess, onError: onError)
		}
	}

	
	//MARK: [Private Methods] Manage Requests
	
	private func getLocationViaIPScan(_ timeout: TimeInterval = DefaultTimeout, onSuccess:LocationHandlerSuccess, onError: LocationHandlerError) -> Request {
		let URLRequest = Foundation.URLRequest(url: URL(string: "http://ip-api.com/json")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig)
		let task = session.dataTask(with: URLRequest) { (data, response, error) in
			if let data = data as Data? {
				do {
					if let resultDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
						let placemark = try self.parseIPLocationData(resultDict)
						onSuccess(placemark.location!)
					}
				} catch let error as LocationError {
					onError(nil,error)
				} catch let error as NSError {
					onError(nil,LocationError.locationManager(error: error))
				}
			}
		}
		task.resume()
		return task
	}
	
	internal func stopLocationRequest(_ request: LocationRequest) {
		if let idx = self.locationObservers.index(where: {$0.UUID == request.UUID}) {
			self.locationObservers.remove(at: idx)
			self.updateLocationUpdateService()
		}
	}
	
	internal func stopInterestingPlacesRequest(_ request: VisitRequest) -> Bool {
		if let idx = self.visitsObservers.index(where: {$0.UUID == request.UUID}) {
			self.visitsObservers[idx].isEnabled = false
			self.visitsObservers.remove(at: idx)
			self.updateVisitingService()
			return true
		}
		return false
	}
	
	internal func addVisitRequest(_ handler: VisitRequest) -> VisitRequest {
		if self.visitsObservers.index(where: {$0.UUID == handler.UUID}) == nil {
			self.visitsObservers.append(handler)
			handler.isEnabled = true
		}
		self.updateVisitingService()
		return handler
	}
	
	internal func stopHeadingRequest(_ request: HeadingRequest) -> Bool {
		if let idx = self.headingObservers.index(where: {$0.UUID == request.UUID}) {
			self.headingObservers.remove(at: idx)
			self.updateHeadingService()
			return true
		}
		return false
	}
	
	internal func addHeadingRequest(_ handler: HeadingRequest) -> HeadingRequest {
		if self.headingObservers.index(where: {$0.UUID == handler.UUID}) == nil {
			headingObservers.append(handler)
		}
		self.updateHeadingService()
		return handler
	}
	
	internal func addLocationRequest(_ handler: LocationRequest) -> LocationRequest {
		if self.locationObservers.index(where: {$0.UUID == handler.UUID}) == nil {
			locationObservers.append(handler)
		}
		self.updateLocationUpdateService()
		return handler
	}
	
	internal func updateHeadingService() {
		let enabledObservers = headingObservers.filter({ $0.isEnabled == true })
		if enabledObservers.count == 0 {
			self.manager.stopUpdatingHeading()
			return
		}
		
		let minAngle = enabledObservers.min(by: {return ($0.accuracy < $1.accuracy) })!.accuracy
		self.manager.headingFilter = minAngle
		self.manager.headingOrientation = self.headingOrientation
		self.manager.startUpdatingHeading()
	}
	
	internal func updateVisitingService() {
		let enabledObservers = visitsObservers.filter({ $0.isEnabled == true })
		if enabledObservers.count == 0 {
			self.manager.stopMonitoringVisits()
		} else {
			self.manager.startMonitoringVisits()
		}
	}
	
	internal func updateLocationUpdateService() {
		let enabledObservers = locationObservers.filter({ $0.isEnabled == true })
		if enabledObservers.count == 0 {
			self.manager.stopUpdatingLocation()
			self.manager.stopMonitoringSignificantLocationChanges()
			return
		}
		
		do {
			let requestShouldBeMade = try self.requestLocationServiceAuthorizationIfNeeded()
			if requestShouldBeMade == true {
				return
			}
		} catch let err {
			self.cleanUpAllLocationRequests( (err as! LocationError) )
		}
		
		var globalAccuracy: Accuracy?
		var globalFrequency: UpdateFrequency?
		var activityType: CLActivityType = .other
		
		for (_,observer) in enabledObservers.enumerated() {
			if (globalAccuracy == nil || observer.accuracy.rawValue > globalAccuracy!.rawValue) {
				globalAccuracy = observer.accuracy
			}
			if (globalFrequency == nil || observer.frequency < globalFrequency) {
				globalFrequency = observer.frequency
			}
			activityType = (observer.activityType.rawValue > activityType.rawValue ? observer.activityType : activityType)
		}
		
		self.manager.activityType = activityType
		
		if (globalFrequency == .significant) {
			self.manager.stopUpdatingLocation()
			self.manager.startMonitoringSignificantLocationChanges()
		} else {
			self.manager.stopMonitoringSignificantLocationChanges()
			self.manager.startUpdatingLocation()
		}
	}
	
	private func requestLocationServiceAuthorizationIfNeeded() throws -> Bool {
		if CLLocationManager.locationAuthStatus == .authorized(always: true) || CLLocationManager.locationAuthStatus == .authorized(always: false) {
			return false
		}
		
		switch CLLocationManager.bundleLocationAuthType {
		case .none:
			throw LocationError.missingAuthorizationInPlist
		case .always:
			self.manager.requestAlwaysAuthorization()
			self.allowsBackgroundEvents = true
			self.manager.pausesLocationUpdatesAutomatically = self.pausesLocationUpdatesWhenPossible
		case .onlyInUse:
			self.allowsBackgroundEvents = false
			self.manager.pausesLocationUpdatesAutomatically = self.pausesLocationUpdatesWhenPossible
			self.manager.requestWhenInUseAuthorization()
		}
		
		self.pauseAllLocationRequest()
		return true
	}
	
	private func pauseAllLocationRequest() {
		self.locationObservers.forEach { handler in
            if handler.isEnabled {
                handler.pause()
            }
		}
	}
	
	private func cleanUpAllLocationRequests(_ error: LocationError) {
		self.locationObservers.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: error, location: nil)
		}
	}
	
	private func startAllLocationRequests() {
		self.locationObservers.forEach { handler in
			handler.start()
		}
	}
	
	//MARK: [Private Methods] Location Manager Delegate
	
	@objc public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
		self.visitsObservers.forEach { handler in
			if (handler.isEnabled == true) {
				handler.onDidVisitPlace?(visit)
			}
		}
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .denied, .restricted:
			self.cleanUpAllLocationRequests(LocationError.authorizationDidChange(newStatus: status))
		case .authorizedAlways, .authorizedWhenInUse:
			self.startAllLocationRequests()
		default:
			break
		}
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		self.locationObservers.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: LocationError.locationManager(error: error), location: nil)
		}
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		self.lastLocation = locations.max(by: { (l1, l2) -> Bool in
			return l1.timestamp.timeIntervalSince1970 < l2.timestamp.timeIntervalSince1970}
		)
		self.locationObservers.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: nil, location: self.lastLocation)
		}
	}
	
	public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
		self.locationObservers.forEach { handler in
			handler.onPausesHandler?(handler.lastLocation)
		}
	}
	
	//MARK: [Private Methods] Heading
	
	public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.headingObservers.forEach { headingRequest in headingRequest.didReceiveEventFromManager(nil, heading: newHeading) }
	}
	
	public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
		for (_,request) in self.headingObservers.enumerated() {
			if request.allowsCalibration == true { return true }
			return false
		}
		return false
	}
	
	//MARK: [Private Methods] Reverse Address/Location
	
	private func reverse_apple(address: String, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
			if error != nil {
				fHandler(LocationError.locationManager(error: error))
			} else {
				if let placemark = placemarks?[0] {
					sHandler(placemark)
				} else {
					fHandler(LocationError.noDataReturned)
				}
			}
		})
		return geocoder
	}
	
	private func reverse_google(address: String, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)"
		if self.googleAPIKey != nil {
			APIURLString = "\(APIURLString)&key=\(self.googleAPIKey!)"
		}
		let APIURL = URL(string: APIURLString)
		let APIURLRequest = URLRequest(url: APIURL!)
		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig)
		let task = session.dataTask(with: APIURLRequest) { (data, response, error) in
			if error != nil {
				fHandler(LocationError.locationManager(error: error))
			} else {
				if data != nil {
					let jsonResult: NSDictionary = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)) as! NSDictionary
					let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
					if noResults == true { // request is ok but not results are returned
						fHandler(LocationError.noDataReturned)
					} else if (error != nil) { // something went wrong with request
						fHandler(LocationError.locationManager(error: error))
					} else { // we have some good results to show
						let placemark = self.parseGoogleLocationData(jsonResult)
						sHandler(placemark)
					}
				}
			}
		}
		task.resume()
		return task
	}
	
	private func reverse_location_apple(_ location: CLLocation, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			if (placemarks?.count > 0) {
				let placemark: CLPlacemark! = placemarks![0]
				if (placemark.locality != nil && placemark.administrativeArea != nil) {
					sHandler(placemark)
				}
			} else {
				fHandler(LocationError.locationManager(error: error))
			}
		}
		return geocoder
	}
	
	private func reverse_location_google(_ location: CLLocation,  onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.coordinate.latitude),\(location.coordinate.longitude)"
		if self.googleAPIKey != nil {
			APIURLString = "\(APIURLString)&key=\(self.googleAPIKey!)"
		}
		APIURLString = APIURLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
		let APIURL = URL(string: APIURLString)
		let APIURLRequest = URLRequest(url: APIURL!)
		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig)
		let task = session.dataTask(with: APIURLRequest) { (data, response, error) in
			if error != nil {
				fHandler(LocationError.locationManager(error: error))
			} else {
				if data != nil {
					let jsonResult: NSDictionary = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)) as! NSDictionary
					let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
					if noResults == true { // request is ok but not results are returned
						fHandler(LocationError.noDataReturned)
					} else if (error != nil) { // something went wrong with request
						fHandler(LocationError.locationManager(error: error))
					} else { // we have some good results to show
						let placemark = self.parseGoogleLocationData(jsonResult)
						sHandler(placemark)
					}
				}
			}
		}
		task.resume()
		return task
	}
	
	//MARK: [Private Methods] Parsing
	
	private func parseIPLocationData(_ resultDict: NSDictionary) throws -> CLPlacemark {
		let status = resultDict["status"] as? String
		if status != "success" {
			throw LocationError.noDataReturned
		}
		
		var addressDict = [String:AnyObject]()
		addressDict[CLPlacemarkDictionaryKey.kCountry] = resultDict["country"] as! NSString
		addressDict[CLPlacemarkDictionaryKey.kCountryCode] = resultDict["countryCode"] as! NSString
		addressDict[CLPlacemarkDictionaryKey.kPostCodeExtension] = resultDict["zip"] as! NSString
		
		var coordinates = CLLocationCoordinate2DMake(0, 0)
		if let lat = resultDict["lat"] as? NSNumber, let lon = resultDict["lon"] as? NSNumber {
			coordinates = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)
		}
		
		let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: addressDict)
		return (placemark as CLPlacemark)
	}
	
	private func parseGoogleLocationData(_ resultDict: NSDictionary) -> CLPlacemark {
		let locationDict = (resultDict.value(forKey: "results") as! NSArray).firstObject as! NSDictionary
		
		var addressDict = [String:AnyObject]()
		
		// Parse coordinates
		let geometry = locationDict.object(forKey: "geometry") as! NSDictionary
		let location = geometry.object(forKey: "location") as! NSDictionary
		let coordinate = CLLocationCoordinate2D(latitude: location.object(forKey: "lat") as! Double, longitude: location.object(forKey: "lng") as! Double)
		
		let addressComponents = locationDict.object(forKey: "address_components") as! NSArray
		let formattedAddressArray = (locationDict.object(forKey: "formatted_address") as! NSString).components(separatedBy: ", ") as Array
		
		addressDict[CLPlacemarkDictionaryKey.kSubAdministrativeArea] = JSONComponent("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kSubLocality] = JSONComponent("subLocality", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kState] = JSONComponent("administrative_area_level_1", inArray: addressComponents, ofType: "short_name")
		addressDict[CLPlacemarkDictionaryKey.kStreet] = formattedAddressArray.first! as NSString
		addressDict[CLPlacemarkDictionaryKey.kThoroughfare] = JSONComponent("route", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kFormattedAddressLines] = formattedAddressArray
		addressDict[CLPlacemarkDictionaryKey.kSubThoroughfare] = JSONComponent("street_number", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kPostCodeExtension] = ""
		addressDict[CLPlacemarkDictionaryKey.kCity] = JSONComponent("locality", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kZIP] = JSONComponent("postal_code", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kCountry] = JSONComponent("country", inArray: addressComponents, ofType: "long_name")
		addressDict[CLPlacemarkDictionaryKey.kCountryCode] = JSONComponent("country", inArray: addressComponents, ofType: "short_name")
		
		let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
		return (placemark as CLPlacemark)
	}
	
	private func JSONComponent(_ component:NSString,inArray:NSArray,ofType:NSString) -> NSString {
		let index: Int = inArray.indexOfObject(options: .concurrent, passingTest: { (obj,idx,stop) -> Bool in
			let objDict:NSDictionary = obj as! NSDictionary
			let types:NSArray = objDict.object(forKey: "types") as! NSArray
			let type = types.firstObject as! NSString
			return type.isEqual(to: component as String)
		})
		
		if index == NSNotFound { return "" }
		if index >= inArray.count { return "" }
		let type = ((inArray.object(at: index) as! NSDictionary).value(forKey: ofType as String)!) as! NSString
		if type.length > 0 { return type }
		return ""
	}
	
	private func validateGoogleJSONResponse(_ jsonResult: NSDictionary!) -> (error: NSError?, noResults: Bool?) {
		var status = jsonResult.value(forKey: "status") as! NSString
		status = status.lowercased
		if status.isEqual(to: "ok") == true { // everything is fine, the sun is shining and we have results!
			return (nil,false)
		} else if status.isEqual(to: "zero_results") == true { // No results error
			return (nil,true)
		} else if status.isEqual(to: "over_query_limit") == true { // Quota limit was excedeed
			let message	= "Query quota limit was exceeded"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		} else if status.isEqual(to: "request_denied") == true { // Request was denied
			let message	= "Request denied"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		} else if status.isEqual(to: "invalid_request") == true { // Invalid parameters
			let message	= "Invalid input sent"
			return (NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message]),false)
		}
		return (nil,false) // okay!
	}
	
}
