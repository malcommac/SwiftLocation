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

let DefaultTimeout: NSTimeInterval = 30.0

public let Location:LocationManager = LocationManager()

public class LocationManager: NSObject, CLLocationManagerDelegate {
	//MARK: Public Variables
	public private(set) var lastLocation: CLLocation?
	
	/// You can specify a valid Google API Key if you want to use Google geocoding services without a strict quota
	public var googleAPIKey: String?
	
	/// You can set a Pro key for the ip-api.com service in case of a commercial use or simple wanting better results.
	public var ipAPIKey: String?
	
		/// A Boolean value indicating whether the app wants to receive location updates when suspended. By default it's false.
		/// See .allowsBackgroundLocationUpdates of CLLocationManager for a detailed description of this var.
	public var allowsBackgroundEvents: Bool = false {
		didSet {
			if #available(iOS 9.0, *) {
				if let backgroundModes = NSBundle.mainBundle().objectForInfoDictionaryKey("UIBackgroundModes") as? NSArray {
					if backgroundModes.containsObject("location") {
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
	public var headingOrientation: CLDeviceOrientation = .FaceUp {
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
	public override init() {
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
	public func getLocation(withAccuracy accuracy: Accuracy, frequency: UpdateFrequency = .OneShot, timeout: NSTimeInterval? = nil, onSuccess: LocationHandlerSuccess, onError: LocationHandlerError) -> Request {
		
		if accuracy == .IPScan {
			// Location via IP scan works in a different way
			return self.getLocationViaIPScan(timeout, onSuccess: onSuccess, onError: onError)
		} else {
			let request = LocationRequest(withAccuracy: accuracy, andFrequency: frequency)
			request.locator = self
			request.timeout = timeout
			request.onSuccess(onSuccess)
			request.onError(onError)
			
			if frequency == .Significant && CLLocationManager.significantLocationChangeMonitoringAvailable() == false {
				// Significant location is not supported by this device, cannot start request
				request.onErrorHandler?(nil,LocationError.NotSupported)
				return request
			}
			// Start request
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
	public func getHeading(frequency: HeadingFrequency = .Continuous(interval: nil), accuracy: CLLocationDirection, allowsCalibration: Bool = true, didUpdate update: HeadingHandlerSuccess, onError error: HeadingHandlerError) -> Request {
		let request = HeadingRequest(withFrequency: frequency, accuracy: accuracy, allowsCalibration: allowsCalibration)
		request.locator = self
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
		request.locator = self
		request.start()
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
	public func reverse(address address: String, using service: ReverseService = .Apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
		switch service {
		case .Apple:
			return self.reverse_apple(address: address, onSuccess: onSuccess, onError: onError)
		case .Google:
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
	
	public func reverse(coordinates coordinates: CLLocationCoordinate2D, using service:ReverseService = .Apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
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
	public func reverse(location location: CLLocation, using service :ReverseService = .Apple, onSuccess: RLocationSuccessHandler, onError: RLocationErrorHandler) -> Request {
		switch service {
		case .Apple:
			return self.reverse_location_apple(location, onSuccess: onSuccess, onError: onError)
		case .Google:
			return self.reverse_location_google(location, onSuccess: onSuccess, onError: onError)
		}
	}

	/**
	Call this method in situations where you want location data with GPS accuracy but do not need to process that data right away. Keep in mind: this settings is global and affect all requests.
	To cancel deferred updates pass nil to both parameters or call stopDeferredLocationUpdates() function.
	If your app is in the background and the system is able to optimize its power usage, the location manager tells the GPS hardware to store new locations internally until the specified distance or timeout conditions are met.
	If you want to change the deferral criteria for any reason, and therefore call this method again, be prepared to receive a deferredCanceled error in your request callbacks.
	
	- parameter distance: The distance (in meters) from the current location that must be travelled before event delivery resumes. Pass nil to ignore this condition.
	- parameter timeout:  The amount of time (in seconds) from the current time that must pass before event delivery resumes. Pass nil to ignore this condition.
	
	- returns: true if deferred update are supported, false otherwise
	*/
	public func deferLocationUpdates(untilTravelled distance: CLLocationDistance?, timeout: NSTimeInterval?) -> Bool {
		if CLLocationManager.deferredLocationUpdatesAvailable() == false {
			return false
		}
		if distance != nil || timeout != nil {
			// In order to work properly when you set a deferred location distanceFilter property
			// of the location manager must be set to kCLDistanceFilterNone.
			self.minimumDistance = nil
		}
		if distance == nil && timeout == nil { // Reset deferred locations
			self.manager.disallowDeferredLocationUpdates()
		} else { // Start deferring location updates
			self.manager.allowDeferredLocationUpdatesUntilTraveled(distance ??  CLLocationDistanceMax, timeout: timeout ??  CLTimeIntervalMax)
		}
		return true
	}
	
	/**
	Start any pending location request. Usually you don't need to use this function.
	*/
	public func startAllLocationRequests() {
		self.locationObservers.filter { $0.rState.isPending }.forEach { $0.start() }
		self.visitsObservers.filter { $0.rState.isPending }.forEach { $0.start() }
	}
	
	/**
	Start any pending heading request. Usually you don't need to use this function.
	*/
	public func startAllHeadingRequests() {
		self.headingObservers.filter { $0.rState.isPending }.forEach { $0.start() }
	}
	
	/**
	Stop or pause any location request
	
	- parameter error: optional error to pass
	- parameter pause: true if you want to pause requests instead of cancel them
	*/
	public func stopAllLocationRequests(withError error: LocationError?, pause: Bool = false) {
		if pause == true {
			self.locationObservers.forEach { $0.pause() }
		} else {
			self.locationObservers.forEach { $0.didReceiveEventFromLocationManager(error: error, location: nil) }
		}
	}
	
	/**
	Stop or pause any running significant location request
	
	- parameter pause: true if you want to pause requests instead of cancel them
	*/
	public func stopSignificantLocationRequests(pause: Bool = false) {
		self.locationObservers.filter { $0.rState.isRunning && $0.frequency == .Significant }.forEach {
			if pause == true {
				$0.pause()
			} else {
				$0.cancel(nil)
			}
		}
	}
	
	/**
	Stop receiving deferred location updates
	*/
	public func stopDeferredLocationUpdates() {
		self.deferLocationUpdates(untilTravelled: nil, timeout: nil)
	}
	
	/// The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
	/// By default is nil, each event is reported without any filter.
	public var minimumDistance: CLLocationDistance? {
		didSet {
			self.manager.distanceFilter = (minimumDistance == nil ? kCLDistanceFilterNone : minimumDistance!)
		}
	}
	
	//MARK: [Private Methods] Manage Requests
	
	private func getLocationViaIPScan(timeout: NSTimeInterval?, onSuccess:LocationHandlerSuccess, onError: LocationHandlerError) -> Request {
		var urlPrefix = "http://"
		var keyParam = ""
		
		if let key = ipAPIKey {
			urlPrefix = "https://pro."
			keyParam = "&key=\(key)"
		}
		let urlString = "\(urlPrefix)ip-api.com/json?fields=lat,lon,status,country,countryCode,zip\(keyParam)"
		let URLRequest = NSURLRequest(URL: NSURL(string: urlString)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout ?? DefaultTimeout)
		
		let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: sessionConfig)
		let task = session.dataTaskWithRequest(URLRequest) { (data, response, error) in
			if let data = data as NSData? {
				do {
					if let resultDict = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary {
						let placemark = try self.parseIPLocationData(resultDict)
						onSuccess(placemark.location!)
					}
				} catch let error as LocationError {
					onError(nil,error)
				} catch let error as NSError {
					onError(nil,LocationError.LocationManager(error: error))
				}
			}
		}
		task.resume()
		return task
	}
	
	internal func add(request: Request?) -> Bool {
		guard let request = request else { return false }
		if request.rState.isCancelled == true { return false }
		
		if let request = request as? VisitRequest {
			if self.visitsObservers.indexOf({$0.UUID == request.UUID}) == nil {
				self.visitsObservers.append(request)
			}
			self.updateVisitingService()
			return true
		}
		else if let request = request as? HeadingRequest {
			if self.headingObservers.indexOf({$0.UUID == request.UUID}) == nil {
				self.headingObservers.append(request)
			}
			self.updateHeadingService()
		}
		else if let request = request as? LocationRequest {
			if self.locationObservers.indexOf({$0.UUID == request.UUID}) == nil {
				self.locationObservers.append(request)
			}
			self.updateLocationUpdateService()
			return true
		}
		return false
	}
	
	internal func remove(request: Request?) -> Bool {
		guard let request = request else { return false }
		if request.rState.isRunning == false { return false }

		if let request = request as? VisitRequest {
			guard let idx = self.visitsObservers.indexOf({$0.UUID == request.UUID}) else {
				return false
			}
			self.visitsObservers.removeAtIndex(idx)
			self.updateVisitingService()
			return true
		}
		else if let request = request as? HeadingRequest {
			guard let idx = self.headingObservers.indexOf({$0.UUID == request.UUID}) else {
				return false
			}
			self.headingObservers.removeAtIndex(idx)
			self.updateHeadingService()
		}
		else if let request = request as? LocationRequest {
			guard let idx = self.locationObservers.indexOf({$0.UUID == request.UUID}) else {
				return false
			}
			self.locationObservers.removeAtIndex(idx)
			self.updateLocationUpdateService()
			return true
		}
		return false
	}
	
	
	internal func updateHeadingService() {
		let enabledObservers = headingObservers.filter({ $0.rState.isRunning == true })
		if enabledObservers.count == 0 {
			self.manager.stopUpdatingHeading()
			return
		}
		
		let minAngle = enabledObservers.minElement({return ($0.accuracy == nil || $0.accuracy < $1.accuracy) })!.accuracy
		self.manager.headingFilter = minAngle
		self.manager.headingOrientation = self.headingOrientation
		self.manager.startUpdatingHeading()
	}
	
	internal func updateVisitingService() {
		let enabledObservers = visitsObservers.filter({ $0.rState.isRunning == true })
		if enabledObservers.count == 0 {
			self.manager.stopMonitoringVisits()
		} else {
			self.manager.startMonitoringVisits()
		}
	}
	
	private func setAllStates(to state: RequestState) {
		self.visitsObservers.forEach({ $0.rState = state})
		self.locationObservers.forEach({ $0.rState = state})
		self.headingObservers.forEach({ $0.rState = state})
	}
	
	private func dispatchAuthorizationDidChange(newStatus: CLAuthorizationStatus) {
		func _dispatch(request: Request) {
			request.onAuthorizationDidChange?(newStatus)
		}
		
		self.visitsObservers.forEach({ _dispatch($0) })
		self.locationObservers.forEach({ _dispatch($0) })
		self.headingObservers.forEach({ _dispatch($0) })
	}
	
	internal func updateLocationUpdateService() {
		let enabledObservers = locationObservers.filter({ $0.rState.isRunning == true })
		if enabledObservers.count == 0 {
			self.manager.stopUpdatingLocation()
			self.manager.stopMonitoringSignificantLocationChanges()
			return
		}
		
		do {
			let requestShouldBeMade = try self.requestLocationServiceAuthorizationIfNeeded()
			if requestShouldBeMade == true {
				setAllStates(to: .WaitingUserAuth)
				return
			}
		} catch let err {
			self.stopAllLocationRequests(withError: (err as! LocationError), pause: false)
		}
		
		var globalAccuracy: Accuracy?
		var globalFrequency: UpdateFrequency?
		var activityType: CLActivityType = .Other
		
		for (_,observer) in enabledObservers.enumerate() {
			if (globalAccuracy == nil || observer.accuracy.rawValue > globalAccuracy!.rawValue) {
				globalAccuracy = observer.accuracy
			}
			if (globalFrequency == nil || observer.frequency < globalFrequency) {
				globalFrequency = observer.frequency
			}
			activityType = (observer.activityType.rawValue > activityType.rawValue ? observer.activityType : activityType)
		}
		
		self.manager.activityType = activityType
		
		if (globalFrequency == .Significant) {
			self.manager.stopUpdatingLocation()
			self.manager.startMonitoringSignificantLocationChanges()
		} else {
			self.manager.stopMonitoringSignificantLocationChanges()
			self.manager.startUpdatingLocation()
		}
	}
	
	private func requestLocationServiceAuthorizationIfNeeded() throws -> Bool {
		if CLLocationManager.locationAuthStatus == .Authorized(always: true) || CLLocationManager.locationAuthStatus == .Authorized(always: false) {
			return false
		}
		
		switch CLLocationManager.bundleLocationAuthType {
		case .None:
			throw LocationError.MissingAuthorizationInPlist
		case .Always:
			self.manager.requestAlwaysAuthorization()
			self.allowsBackgroundEvents = true
			self.manager.pausesLocationUpdatesAutomatically = self.pausesLocationUpdatesWhenPossible
		case .OnlyInUse:
			self.allowsBackgroundEvents = false
			self.manager.pausesLocationUpdatesAutomatically = self.pausesLocationUpdatesWhenPossible
			self.manager.requestWhenInUseAuthorization()
		}
		
		self.stopAllLocationRequests(withError: nil, pause: true)
		return true
	}

	
	//MARK: [Private Methods] Location Manager Delegate
	
	@objc public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		switch status {
		case .Denied, .Restricted:
			self.stopAllLocationRequests(withError: LocationError.AuthorizationDidChange(newStatus: status), pause: false)
		case .AuthorizedAlways, .AuthorizedWhenInUse:
			self.startAllLocationRequests()
			self.startAllHeadingRequests()
		default:
			break
		}
		// Dispatch any request which listen for authorization changes
		self.dispatchAuthorizationDidChange(status)
	}
	
	@objc public func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
		self.visitsObservers.filter { $0.rState.isRunning}.filter { $0.rState.isRunning }.forEach { $0.onDidVisitPlace?(visit) }
	}
	
	@objc public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		self.locationObservers.filter { $0.rState.isRunning}.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: LocationError.LocationManager(error: error), location: nil)
		}
	}
	
	@objc public func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
		guard let error = error else { return }
		self.locationObservers.filter { $0.rState.isRunning}.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: LocationError.LocationManager(error: error), location: nil)
		}
	}
	
	@objc public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {		
		self.lastLocation = locations.maxElement({ (l1, l2) -> Bool in
			return l1.timestamp.timeIntervalSince1970 < l2.timestamp.timeIntervalSince1970}
		)
		
		self.locationObservers.filter { $0.rState.isRunning}.forEach { handler in
			handler.didReceiveEventFromLocationManager(error: nil, location: self.lastLocation)
		}
	}
	
	public func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
		self.locationObservers.filter { $0.rState.isRunning}.forEach { handler in
			handler.onPausesHandler?(handler.lastLocation)
		}
	}
	
	//MARK: [Private Methods] Heading
	
	public func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.headingObservers.filter { $0.rState.isRunning}.forEach { headingRequest in headingRequest.didReceiveEventFromManager(nil, heading: newHeading) }
	}
	
	public func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
		for (_,request) in self.headingObservers.enumerate() {
			if request.allowsCalibration == true { return true }
			return false
		}
		return false
	}
	
	//MARK: [Private Methods] Reverse Address/Location
	
	private func reverse_apple(address address: String, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
			if error != nil {
				fHandler(LocationError.LocationManager(error: error))
			} else {
				if let placemark = placemarks?[0] {
					sHandler(placemark)
				} else {
					fHandler(LocationError.NoDataReturned)
				}
			}
		})
		return geocoder
	}
	
	private func reverse_google(address address: String, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)"
		if self.googleAPIKey != nil {
			APIURLString = "\(APIURLString)&key=\(self.googleAPIKey!)"
		}
		let APIURL = NSURL(string: APIURLString)
		let APIURLRequest = NSURLRequest(URL: APIURL!)
		let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: sessionConfig)
		let task = session.dataTaskWithRequest(APIURLRequest) { (data, response, error) in
			if error != nil {
				fHandler(LocationError.LocationManager(error: error))
			} else {
				if data != nil {
					let jsonResult: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
					let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
					if noResults == true { // request is ok but not results are returned
						fHandler(LocationError.NoDataReturned)
					} else if (error != nil) { // something went wrong with request
						fHandler(LocationError.LocationManager(error: error))
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
	
	private func reverse_location_apple(location: CLLocation, onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			if (placemarks?.count > 0) {
				let placemark: CLPlacemark! = placemarks![0]
				if (placemark.locality != nil && placemark.administrativeArea != nil) {
					sHandler(placemark)
				}
			} else {
				fHandler(LocationError.LocationManager(error: error))
			}
		}
		return geocoder
	}
	
	private func reverse_location_google(location: CLLocation,  onSuccess sHandler: RLocationSuccessHandler, onError fHandler: RLocationErrorHandler) -> Request {
		var APIURLString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.coordinate.latitude),\(location.coordinate.longitude)"
		if self.googleAPIKey != nil {
			APIURLString = "\(APIURLString)&key=\(self.googleAPIKey!)"
		}
		APIURLString = APIURLString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
		let APIURL = NSURL(string: APIURLString)
		let APIURLRequest = NSURLRequest(URL: APIURL!)
		let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: sessionConfig)
		let task = session.dataTaskWithRequest(APIURLRequest) { (data, response, error) in
			if error != nil {
				fHandler(LocationError.LocationManager(error: error))
			} else {
				if data != nil {
					let jsonResult: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
					let (error,noResults) = self.validateGoogleJSONResponse(jsonResult)
					if noResults == true { // request is ok but not results are returned
						fHandler(LocationError.NoDataReturned)
					} else if (error != nil) { // something went wrong with request
						fHandler(LocationError.LocationManager(error: error))
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
	
	private func parseIPLocationData(resultDict: NSDictionary) throws -> CLPlacemark {
		let status = resultDict["status"] as? String
		if status != "success" {
			throw LocationError.NoDataReturned
		}
		
		var addressDict = [String:AnyObject]()
		addressDict[CLPlacemarkDictionaryKey.kCountry] = resultDict["country"] as! NSString
		addressDict[CLPlacemarkDictionaryKey.kCountryCode] = resultDict["countryCode"] as! NSString
		addressDict[CLPlacemarkDictionaryKey.kPostCodeExtension] = resultDict["zip"] as! NSString
		
		var coordinates = CLLocationCoordinate2DMake(0, 0)
		if let lat = resultDict["lat"] as? NSNumber, lon = resultDict["lon"] as? NSNumber {
			coordinates = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)
		}
		
		let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: addressDict)
		return (placemark as CLPlacemark)
	}
	
	private func parseGoogleLocationData(resultDict: NSDictionary) -> CLPlacemark {
		let locationDict = (resultDict.valueForKey("results") as! NSArray).firstObject as! NSDictionary
		
		var addressDict = [String:AnyObject]()
		
		// Parse coordinates
		let geometry = locationDict.objectForKey("geometry") as! NSDictionary
		let location = geometry.objectForKey("location") as! NSDictionary
		let coordinate = CLLocationCoordinate2D(latitude: location.objectForKey("lat") as! Double, longitude: location.objectForKey("lng") as! Double)
		
		let addressComponents = locationDict.objectForKey("address_components") as! NSArray
		let formattedAddressArray = (locationDict.objectForKey("formatted_address") as! NSString).componentsSeparatedByString(", ") as Array
		
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
	
	private func JSONComponent(component:NSString,inArray:NSArray,ofType:NSString) -> NSString {
		let index:NSInteger = inArray.indexOfObjectPassingTest { (obj, idx, stop) -> Bool in
			let objDict:NSDictionary = obj as! NSDictionary
			let types:NSArray = objDict.objectForKey("types") as! NSArray
			let type = types.firstObject as! NSString
			return type.isEqualToString(component as String)
		}
		
		if index == NSNotFound { return "" }
		if index >= inArray.count { return "" }
		let type = ((inArray.objectAtIndex(index) as! NSDictionary).valueForKey(ofType as String)!) as! NSString
		if type.length > 0 { return type }
		return ""
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
	
}
