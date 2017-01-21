//
//  LocationManager.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

public let Location = LocationTracker.shared

public final class LocationTracker: NSObject, CLLocationManagerDelegate {

	public typealias RequestPoolDidChange = ((Any) -> (Void))
	
	/// This is a reference to LocationManager's singleton where the main queue for Requests.
	static let shared : LocationTracker = {
		let instance = LocationTracker()
		return instance
	}()
	
	/// Initialize func
	private override init() {
		self.locationManager = CLLocationManager()
		super.init()
		self.locationManager.delegate = self
		
		// Listen for any change (add or remove) into all queues
		let onAddHandler: ((Any) -> (Void)) = { self.onAddNewRequest?($0) }
		let onRemoveHandler: ((Any) -> (Void)) = { self.onRemoveRequest?($0) }
		for var pool in self.pools {
			pool.onAdd = onAddHandler
			pool.onRemove = onRemoveHandler
		}
	}
	
	public override var description: String {
		let countRunning: Int = self.pools.reduce(0, { $0 + $1.countRunning })
		let countPaused: Int = self.pools.reduce(0, { $0 + $1.countPaused })
		let countAll: Int = self.pools.reduce(0, { $0 + $1.count })
		var status = "TRACKER STATUS\n - \(countRunning) Running\n - \(countPaused) Paused\n - \(countAll) Total"
		if let settings = self.locationSettings {
			status += "\n- SETTINGS:\(settings)"
		} else {
			status += "\n- SETTINGS: All off"
		}
		return status
	}
	
	/// Callback called when a new request is added
	public var onAddNewRequest: RequestPoolDidChange? = nil
	
	/// Callback called when a request was removed
	public var onRemoveRequest: RequestPoolDidChange? = nil
	
	/// Internal location manager reference
	internal var locationManager: CLLocationManager
	
	/// Queued requests regarding location services
	private var locationsPool: RequestsPool<LocationRequest> = RequestsPool()
	
	/// Queued requests regarding reverse geocoding services
	private var geocodersPool: RequestsPool<GeocoderRequest> = RequestsPool()
	
	/// Queued requests regarding heading services
	private var headingPool: RequestsPool<HeadingRequest> = RequestsPool()

	/// Queued requests regarding region monitor services
	private var regionPool: RequestsPool<RegionRequest> = RequestsPool()
	
	/// Queued requests regarding visits
	private var visitsPool: RequestsPool<VisitsRequest> = RequestsPool()

	/// This represent the status of the authorizations before a change
	private var lastStatus: CLAuthorizationStatus = CLAuthorizationStatus.notDetermined
	
	/// This represent the last locations received (best accurated location and last received location)
	private(set) var lastLocation = LastLocation()
	public struct LastLocation {
		/// This is the best accurated measured location (may be old, check the `timestamp`)
		public var bestAccurated: CLLocation?
		/// This represent the last measured location by timestamp (may be innacurate, check `accuracy`)
		public var last: CLLocation?
		
		/// Store last value
		///
		/// - Parameter location: location to set
		mutating internal func set(location: CLLocation) {
			if bestAccurated == nil {
				self.bestAccurated = location
			} else if location.horizontalAccuracy > self.bestAccurated!.horizontalAccuracy {
				self.bestAccurated = location
			}
			if last == nil {
				self.last = location
			} else if location.timestamp > self.last!.timestamp {
				self.last = location
			}
		}
	}
	
	
	/// Active CoreLocation settings based upon running requests
	private var _locationSettings: Settings?
	private(set) var locationSettings: Settings? {
		set {
			
			func stopLocationServices() {
				locationManager.stopUpdatingLocation()
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.disallowDeferredLocationUpdates()
			}
			
			guard let settings = newValue else {
				stopLocationServices()
				_locationSettings = newValue
				return
			}
			
			if _locationSettings == newValue {
				return // ignore equal settings, avoid multiple sets
			}
			
			_locationSettings = newValue
			// Set attributes for CLLocationManager instance
			locationManager.activityType = settings.activity // activity type (used to better preserve battery based upon activity)
			locationManager.desiredAccuracy = settings.accuracy.meters // accuracy (used to preserve battery based upon update frequency)
			
			switch settings.frequency {
			case .significant:
				guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
					stopLocationServices()
					return
				}
				// If best frequency is significant location update (and hardware supports it) then start only significant location update
				locationManager.stopUpdatingLocation()
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.startMonitoringSignificantLocationChanges()
				locationManager.disallowDeferredLocationUpdates()
			case .whenTravelled(let meters, let timeout):
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.startUpdatingLocation()
				locationManager.allowDeferredLocationUpdates(untilTraveled: meters, timeout: timeout)
			default:
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.allowsBackgroundLocationUpdates = false
				locationManager.startUpdatingLocation()
				locationManager.disallowDeferredLocationUpdates()
			}
		}
		get {
			return _locationSettings
		}
	}
	
	public struct Settings: CustomStringConvertible, Equatable {
		/// Accuracy set
		var accuracy: Accuracy
		
		/// Frequency set
		var frequency: Frequency
		
		/// Activity type set
		var activity: CLActivityType
		
		/// Description of the settings
		public var description: String {
			return "\n\t- Accuracy: '\(accuracy)'\n\t - Frequency: '\(frequency)'\n\t - Activity: '\(activity)'\n"
		}
		
		/// Returns a Boolean value indicating whether two values are equal.
		///
		/// Equality is the inverse of inequality. For any values `a` and `b`,
		/// `a == b` implies that `a != b` is `false`.
		///
		/// - Parameters:
		///   - lhs: A value to compare.
		///   - rhs: Another value to compare.
		public static func ==(lhs: LocationTracker.Settings, rhs: LocationTracker.Settings) -> Bool {
			return (lhs.accuracy.orderValue == rhs.accuracy.orderValue && lhs.frequency == rhs.frequency && lhs.activity == rhs.activity)
		}
	}

	/// This value is measured in meters and allows to generate new events only if horizontal distance
	/// from previous measured point is changed by given `distanceFilter`. By default all events are generated
	/// and passed.
	/// This property is used only in conjunction with the standard location services and is not used when monitoring
	/// significant location changes.
	public var distanceFilter: CLLocationDistance = kCLDistanceFilterNone {
		didSet {
			locationManager.distanceFilter = distanceFilter
		}
	}
	
	/// Asks whether the heading calibration alert should be displayed.
	/// This method is called in an effort to calibrate the onboard hardware used to determine heading values.
	/// Typically at the following times:
	///  - The first time heading updates are ever requested
	///  - When Core Location observes a significant change in magnitude or inclination of the observed magnetic field
	///
	/// If true from this method, Core Location displays the heading calibration alert on top of the current window.
	/// The calibration alert prompts the user to move the device in a particular pattern so that Core Location can
	/// distinguish between the Earth’s magnetic field and any local magnetic fields.
	/// The alert remains visible until calibration is complete or until you explicitly dismiss it by calling the 
	/// dismissHeadingCalibrationDisplay() method.
	public var displayHeadingCalibration: Bool = true
	
	/// When `true` this property is a good way to improve battery life.
	/// This function also scan for any running Request's `activityType` and see if location data is unlikely to change.
	/// If yes (for example when user stops for food while using a navigation app) the location manager might pause updates
	/// for a period of time.
	/// By default is set to `false`.
	public var autoPauseUpdates: Bool = false {
		didSet {
			locationManager.pausesLocationUpdatesAutomatically = autoPauseUpdates
		}
	}
	
	/// The device orientation to use when computing heading values.
	/// When computing heading values, the location manager assumes that the top of the device in portrait mode represents
	/// due north (0 degrees) by default. For apps that run in other orientations, this may not always be the most convenient
	/// orientation.
	///
	/// This property allows you to specify which device orientation you want the location manager to use as the reference
	/// point for due north.
	///
	/// Although you can set the value of this property to unknown, faceUp, or faceDown, doing so has no effect on the
	/// orientation reference point. The original reference point is retained instead.
	/// Changing the value in this property affects only those heading values reported after the change is made.
	public var headingOrientation: CLDeviceOrientation {
		set { locationManager.headingOrientation = headingOrientation }
		get { return locationManager.headingOrientation }
	}
	
	/// You can use this method to dismiss it after an appropriate amount of time to ensure that your app’s user interface
	/// is not unduly disrupted.
	public func dismissHeadingCalibrationDisplay() {
		locationManager.dismissHeadingCalibrationDisplay()
	}
	
	/// Create and enque a new location tracking request
	///
	/// - Parameters:
	///   - accuracy: accuracy of the location request (it may affect device's energy consumption)
	///   - frequency: frequency of the location retrive process (it may affect device's energy consumption)
	///   - timeout: optional timeout. If no location were found before timeout a `LocationError.timeout` error is reported.
	///   - success: success handler to call when a new location were found for this request
	///   - error: error handler to call when an error did occour while searching for request
	/// - Returns: request
	@discardableResult
	public func getLocation(accuracy: Accuracy, frequency: Frequency, timeout: TimeInterval? = nil, success: @escaping LocationRequest.OnSuccessCallback, error: @escaping LocationRequest.OnErrorCallback) -> LocationRequest {
		
		let req = LocationRequest(accuracy: accuracy, frequency: frequency, success, error)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	
	/// Create and enqueue a new reverse geocoding request for an input address string
	///
	/// - Parameters:
	///   - address: address string to reverse
	///   - region: A geographical region to use as a hint when looking up the specified address.
	///				Specifying a region lets you prioritize the returned set of results to locations that are close to some
	///				specific geographical area, which is typically the user’s current location.
	///   - timeout: timeout of the operation; nil to ignore timeout, a valid seconds interval. If reverse geocoding does not succeded or
	///				 fail inside this time interval request fails with `LocationError.timeout` error and registered callbacks are called.
	///
	///   - success: success handler to call when reverse geocoding succeded
	///   - failure: failure handler to call when reverse geocoding fails
	/// - Returns: request
	@discardableResult
	public func getLocation(forString address: String, inRegion region: CLRegion? = nil, timeout: TimeInterval? = nil,
	                        success: @escaping GeocoderCallback.onSuccess, failure: @escaping GeocoderCallback.onError) -> GeocoderRequest {
		let req = GeocoderRequest(address: address, region: region, success, failure)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	
	/// Create and enqueue a new reverse geocoding request for an instance of `CLLocation` object.
	///
	/// - Parameters:
	///   - location: location to reverse
	///   - timeout: timeout of the operation; nil to ignore timeout, a valid seconds interval. If reverse geocoding does not succeded or
	///				 fail inside this time interval request fails with `LocationError.timeout` error and registered callbacks are called.
	///   - success: success handler to call when reverse geocoding succeded
	///   - failure: failure handler to call when reverse geocoding fails
	/// - Returns: request
	@discardableResult
	public func getLocation(forLocation location: CLLocation, timeout: TimeInterval? = nil,
	                        success: @escaping GeocoderCallback.onSuccess, failure: @escaping GeocoderCallback.onError) -> GeocoderRequest {
		let req = GeocoderRequest(location: location, success, failure)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	
	/// Create and enqueue a new reverse geocoding request for an Address Book `Dictionary` object.
	///
	/// - Parameters:
	///   - dict: address book dictionary
	///   - timeout: timeout of the operation; nil to ignore timeout, a valid seconds interval. If reverse geocoding does not succeded or
	///				 fail inside this time interval request fails with `LocationError.timeout` error and registered callbacks are called.
	///   - success: success handler to call when reverse geocoding succeded
	///   - failure: failure handler to call when reverse geocoding fails
	/// - Returns: request
	public func getLocation(forABDictionary dict: [AnyHashable: Any], timeout: TimeInterval? = nil,
	                        success: @escaping GeocoderCallback.onSuccess, failure: @escaping GeocoderCallback.onError) -> GeocoderRequest {
		let req = GeocoderRequest(abDictionary: dict, success, failure)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	
	/// Allows you to receive heading update with a minimum filter degree
	///
	/// - Parameters:
	///   - filter: The minimum angular change (measured in degrees) required to generate new heading events.
	///   - success: succss handler
	///   - failure: failure handler
	/// - Returns: request
	public func getHeading(filter: CLLocationDegrees,
	                       success: @escaping HeadingCallback.onSuccess, failure: @escaping HeadingCallback.onError) throws -> HeadingRequest {
		return try HeadingRequest(filter: filter, success: success, failure: failure)
	}
	
	
	/// Monitor a geographic region identified by a center coordinate and a radius.
	/// Region monitoring
	///
	/// - Parameters:
	///   - center: coordinate center
	///   - radius: radius in meters
	///   - enter: callback for region enter event
	///   - exit: callback for region exit event
	///   - error: callback for errors
	/// - Returns: request
	/// - Throws: throw `LocationError.serviceNotAvailable` if hardware does not support region monitoring
	public func monitor(regionAt center: CLLocationCoordinate2D, radius: CLLocationDistance,
	                    enter: RegionCallback.onEvent?, exit: RegionCallback.onEvent?, error: @escaping RegionCallback.onFailure) throws -> RegionRequest {
		return try RegionRequest(center: center, radius: radius, onEnter: enter, onExit: exit, error: error)
	}
	
	
	/// Monitor a specified region
	///
	/// - Parameters:
	///   - region: region to monitor
	///   - enter: callback for region enter event
	///   - exit: callback for region exit event
	///   - error: callback for errors
	///   - error: callback for errors
	/// - Throws: throw `LocationError.serviceNotAvailable` if hardware does not support region monitoring
	public func monitor(region: CLCircularRegion,
	                    enter: RegionCallback.onEvent?, exit: RegionCallback.onEvent?, error: @escaping RegionCallback.onFailure) throws -> RegionRequest {
		return try RegionRequest(region: region, onEnter: enter, onExit: exit, error: error)
	}
	
	
	/// Calling this method begins the delivery of visit-related events to your app.
	/// Enabling visit events for one location manager enables visit events for all other location manager objects in your app.
	/// When a new visit event arrives callback is called and request still alive until removed.
	/// This service require always authorization.
	///
	/// - Parameters:
	///   - event: callback called when a new visit arrive
	///   - error: callback called when an error occours
	/// - Returns: request
	/// - Throws: throw an exception if app does not support alway authorization
	public func monitorVisit(event: @escaping VisitCallback.onVisit, error: @escaping VisitCallback.onFailure) throws -> VisitsRequest {
		return try VisitsRequest(event: event, error: error)
	}
	
	//MARK: Register/Unregister location requests
	
	/// Register a new request and enqueue it
	///
	/// - Parameter request: request to enqueue
	/// - Returns: `true` if added correctly to the queue, `false` otherwise.
	public func start<T: Request>(_ requests: T...) {
		var hasChanges = false
		for request in requests {
			
			// Location Requests
			if let request = request as? LocationRequest {
			//	let isAppInBackground = (UIApplication.shared.applicationState == .background)
			//	let canStart = (isAppInBackground && request.isBackgroundRequest) || (!isAppInBackground && !request.isBackgroundRequest)
			//	if canStart == true {
					request._state = .running
					if locationsPool.add(request) {
						hasChanges = true
					}
			//	}
			}
			
			// Geocoder Requests
			if let request = request as? GeocoderRequest {
				request._state = .running
				if geocodersPool.add(request) {
					hasChanges = true
				}
			}
			
			// Heading requests
			if let request = request as? HeadingRequest {
				request._state = .running
				if headingPool.add(request) {
					hasChanges = true
				}
			}
			
			// Region Monitoring requests
			if let request = request as? RegionRequest {
				request._state = .running
				if regionPool.add(request) {
					hasChanges = true
				}
			}
		}
		if hasChanges {
			self.updateServicesStatus()
			requests.forEach { $0.onResume() }
		}
	}
	
	
	/// Unregister and stops a queued request
	///
	/// - Parameter request: request to remove
	/// - Returns: `true` if request was removed successfully, `false` if it's not part of the queue
	public func cancel<T: Request>(_ requests: T...) {
		var hasChanges = false
		for request in requests {
			if self.isQueued(request) == false {
				continue
			}
			
			// Location Requests
			if let request = request as? LocationRequest {
				request._state = .idle
				locationsPool.remove(request)
				hasChanges = true
			}
			
			// Geocoder requests
			if let request = request as? GeocoderRequest {
				request._state = .idle
				geocodersPool.remove(request)
				hasChanges = true
			}
			
			// Heading requests
			if let request = request as? HeadingRequest {
				request._state = .idle
				headingPool.remove(request)
				hasChanges = true
			}
			
			// Region Monitoring requests
			if let request = request as? RegionRequest {
				request._state = .idle
				locationManager.stopMonitoring(for: request.region)
				regionPool.remove(request)
				hasChanges = true
			}
		}

		if hasChanges == true {
			self.updateServicesStatus()
			requests.forEach { $0.onCancel() }
		}
	}
	
	/// Pause any passed queued reques
	///
	/// - Parameter requests: requests to pause
	public func pause<T: Request>(_ requests: T...) {
		var hasChanges = false
		for request in requests {
			if self.isQueued(request) == false { continue }
			
			if self.isQueued(request) && request.state.isRunning {
				
				// Location requests
				if let request = request as? LocationRequest {
					request._state = .paused
					hasChanges = true
				}
				
				// Geocoder requests
				if let request = request as? GeocoderRequest {
					request._state = .paused
					hasChanges = true
				}
				
				// Heading requests
				if let request = request as? HeadingRequest {
					request._state = .paused
					hasChanges = true
				}
				
				// Region Monitoring requests
				if let request = request as? RegionRequest {
					locationManager.stopMonitoring(for: request.region)
					request._state = .paused
					hasChanges = true
				}
			}
		}
		
		if hasChanges == true {
			self.updateServicesStatus()
			requests.forEach { $0.onPause() }
		}
	}
	
	
	/// Return `true` if target `request` is part of a queue.
	///
	/// - Parameter request: target request
	/// - Returns: `true` if request is in a queue, `false` otherwise
	internal func isQueued<T: Request>(_ request: T?) -> Bool {
		guard let request = request else { return false }
		
		// Location Request
		if let request = request as? LocationRequest {
			return locationsPool.isQueued(request)
		}
		
		// Geocoder Request
		if let request = request as? GeocoderRequest {
			return geocodersPool.isQueued(request)
		}
		
		// Heading Request
		if let request = request as? HeadingRequest {
			return headingPool.isQueued(request)
		}
		
		// Region Request
		if let request = request as? RegionRequest {
			return regionPool.isQueued(request)
		}
		return false
	}
	
	//MARK: CLLocationManager Visits Delegate
	
	public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
		self.visitsPool.dispatch(value: visit)
	}
	
	//MARK: CLLocationManager Region Monitoring Delegate
	
	public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		let region = self.regionPool.filter { $0.region == region }.first
		region?.onStartMonitoring?()
	}
	
	public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		let region = self.regionPool.filter { $0.region == region }.first
		region?.dispatch(error: error)
	}
	
	public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		let region = self.regionPool.filter { $0.region == region }.first
		region?.dispatch(event: .entered)
	}
	
	public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		let region = self.regionPool.filter { $0.region == region }.first
		region?.dispatch(event: .exited)
	}
	
	public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
		let region = self.regionPool.filter { $0.region == region }.first
		region?.dispatch(state: state)
	}
	
	//MARK: Internal Heading Manager Func
	
	public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.headingPool.dispatch(value: newHeading)
	}
	
	public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
		return self.displayHeadingCalibration
	}
	
	//MARK: Internal Location Manager Func
	
	/// Set the request's `state` for any queued requests which is in one the following states
	///
	/// - Parameters:
	///   - newState: new state to set
	///   - states: request's allowed state to be changed
	private func loc_setRequestState(_ newState: RequestState, forRequestsIn states: Set<RequestState>) {
		locationsPool.forEach {
			if states.contains($0.state) {
				$0._state = newState
			}
		}
	}
	
	/// Evaluate best settings based upon running location requests
	///
	/// - Returns: best settings
	private func locationTrackingBestSettings() -> Settings? {
		guard locationsPool.countRunning > 0 else {
			return nil // no settings, location manager can be disabled
		}
		
		var accuracy: Accuracy = .any
		var frequency: Frequency = .significant
		var type: CLActivityType = .other
		
		for request in locationsPool {
			guard request.state.isRunning else {
				continue // request is not running, can be ignored
			}
			
			if request.accuracy.orderValue > accuracy.orderValue {
				accuracy = request.accuracy
			}
			if request.frequency < frequency {
				frequency = request.frequency
			}
			if request.activity.rawValue > type.rawValue {
				type = request.activity
			}
		}
	
		return Settings(accuracy: accuracy, frequency: frequency, activity: type)
	}

	//MARK: CLLocationManager Location Tracking Delegate
	
	@objc open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		locationsPool.forEach { $0.dispatchAuthChange(self.lastStatus, status) }
		self.lastStatus = status
		
		switch status {
		case .denied, .restricted:
			let error = LocationError.authDidChange(status)
			visitsPool.dispatch(error: error)
			regionPool.dispatch(error: error)
			locationsPool.dispatch(error: error)
			
			self.updateLocationServices()
			self.updateRegionMonitoringServices()
		case .authorizedAlways, .authorizedWhenInUse:
			locationsPool.forEach { $0.resume() }
			regionPool.forEach { $0.resume() }
			visitsPool.forEach { $0.resume() }
			
			self.updateLocationServices()
			self.updateRegionMonitoringServices()
		default:
			break
		}
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.max(by: { (l1, l2) -> Bool in
			return l1.timestamp.timeIntervalSince1970 < l2.timestamp.timeIntervalSince1970}
		) else {
			return
		}
		//print("\(Date())  -> \(location.horizontalAccuracy), \(location.coordinate.latitude), \(location.coordinate.longitude)")
		self.lastLocation.set(location: location)
		locationsPool.forEach { $0.dispatch(location: location) }
	}
	
	//MARK: CLLocationManager Error Delegate
	
	@objc open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		locationsPool.dispatch(error: error)
		headingPool.dispatch(error: error)
		visitsPool.dispatch(error: error)
		regionPool.dispatch(error: error)
	}
	
	//MARK: Update Services Status
	
	
	/// Update services (turn on/off hardware) based upon running requests
	private func updateServicesStatus() {
		let pools = self.pools
		
		func updateAllServices() {
			self.updateLocationServices()
			self.updateHeadingServices()
			self.updateRegionMonitoringServices()
			self.updateVisitsServices()
		}
		
		do {
			// Check if we need to ask for authorization based upon currently running requests
			guard try self.requireAuthorizationIfNeeded() == false else {
				return
			}
			// Otherwise we can continue
			updateAllServices()
		} catch {
			// Something went wrong, stop all...
			self.locationSettings = nil
			// Dispatch error
			pools.forEach { $0.dispatch(error: error) }
		}
	}
	
	private var pools: [RequestsPoolProtocol] {
		let pools: [RequestsPoolProtocol] = [locationsPool, regionPool, visitsPool,geocodersPool,headingPool]
		return pools
	}
	
	private func requireAuthorizationIfNeeded() throws -> Bool {
		func pauseAllRunningRequest() {
			// Mark running requests as pending
			pools.forEach { $0.set(.waitingUserAuth, forRequestsIn: [.running,.idle]) }
		}
		
		// This is the authorization keys set in Info.plist
		let plistAuth = CLLocationManager.appAuthorization
		// Get the max authorization between all running request
		let requiredAuth = self.pools.map({ $0.requiredAuthorization }).reduce(.none, { $0 < $1 ? $0 : $1 })
		// This is the current authorization of CLLocationManager
		let currentAuth = LocAuth.status
		
		print("Required auth is \(requiredAuth)")
		print("Current auth is \(currentAuth)")
		
		if requiredAuth == .none {
			// No authorization are needed
			return false
		}
		
		switch currentAuth {
		case .denied,.disabled, .restricted:
			// Authorization was explicity disabled
			throw LocationError.authorizationDenided
		default:
			if requiredAuth == .always && (currentAuth == .inUseAuthorized || currentAuth == .undetermined) {
				// We need always authorization but we have in-use authorization
				if plistAuth != .always && plistAuth != .both { // we have not set the correct plist key to support this auth
					throw LocationError.missingAuthInInfoPlist
				}
				// Okay we can require it
				pauseAllRunningRequest()
				locationManager.requestAlwaysAuthorization()
				return true
			}
			if requiredAuth == .inuse && currentAuth == .undetermined {
				// We have not set not always or in-use auth plist so we can continue
				if plistAuth != .inuse && plistAuth != .both {
					throw LocationError.missingAuthInInfoPlist
				}
				// require in use authorization
				pauseAllRunningRequest()
				locationManager.requestWhenInUseAuthorization()
				return true
			}
		}
		// We have enough rights to continue without requiring auth
		return false
	}
	
	/// Update visiting services
	internal func updateVisitsServices() {
		guard visitsPool.countRunning > 0 else {
			// There is not any running request, we can stop monitoring all regions
			locationManager.stopMonitoringVisits()
			return
		}
		locationManager.startMonitoringVisits()
	}
	
	/// Update location services based upon running Requests
	internal func updateLocationServices() {
		let hasBackgroundRequests = locationsPool.hasBackgroundRequests()
		
		guard locationsPool.countRunning > 0 else {
			// There is not any running request, we can stop location service to preserve battery.
			self.locationSettings = nil
			return
		}
		
		// Evaluate best accuracy,frequency and activity type based upon all queued requests
		guard let bestSettings = self.locationTrackingBestSettings() else {
			// No need to setup CLLocationManager, stop it.
			self.locationSettings = nil
			return
		}
		
		// Request authorizations if needed
		if bestSettings.accuracy.accuracyRequireAuthorization == true {
			// Check if device supports location services.
			// If not dispatch the error to any running request and stop.
			guard CLLocationManager.locationServicesEnabled() else {
				locationsPool.forEach { $0.dispatch(error: LocationError.serviceNotAvailable) }
				return
			}
		}
		
		// If there is a request which needs background capabilities and we have not set it
		// dispatch proper error.
		if hasBackgroundRequests && CLLocationManager.isBackgroundUpdateEnabled == false {
			locationsPool.forEach { $0.dispatch(error: LocationError.backgroundModeNotSet) }
			return
		}
		
		// Everything is okay we can setup CLLocationManager based upon the most accuracted/most frequent
		// Request queued and running.
		
		let isAppInBackground = (UIApplication.shared.applicationState == .background && CLLocationManager.isBackgroundUpdateEnabled)
		self.locationManager.allowsBackgroundLocationUpdates = isAppInBackground
		if isAppInBackground { self.autoPauseUpdates = false }
		
		// Resume any paused request (a paused request is in `.waitingUserAuth`,`.paused` or `.failed`)
		locationsPool.iterate([.waitingUserAuth]) { $0.resume() }
		
		// Setup with best settings
		self.locationSettings = bestSettings
	}
	
	
	internal func updateRegionMonitoringServices() {
		// Region monitoring is not available for this hardware
		guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
			regionPool.dispatch(error: LocationError.serviceNotAvailable)
			return
		}
		
		// Region monitoring require always authorizaiton, if not generate error
		guard CLLocationManager.appAuthorization == .always else {
			regionPool.dispatch(error: LocationError.requireAlwaysAuth)
			return
		}
		
		guard regionPool.countRunning > 0 else {
			// There is not any running request, we can stop monitoring all regions
			locationManager.stopMonitoringAllRegions()
			return
		}
		
		// Monitor queued regions
		regionPool.forEach {
			if $0.state.isRunning {
				locationManager.startMonitoring(for: $0.region)
			}
		}
	}
	
	internal func updateHeadingServices() {
		// Heading service is not available on current hardware
		guard CLLocationManager.headingAvailable() else {
			self.headingPool.dispatch(error: LocationError.serviceNotAvailable)
			return
		}
		
		guard headingPool.countRunning > 0 else {
			// There is not any running request, we can stop location service to preserve battery.
			locationManager.stopUpdatingHeading()
			return
		}
		
		// Find max accuracy in reporting heading and set it
		var bestHeading: CLLocationDegrees = Double.infinity
		for request in headingPool {
			guard let filter = request.filter else {
				bestHeading = kCLHeadingFilterNone
				break
			}
			bestHeading = min(bestHeading,filter)
		}
		locationManager.headingFilter = bestHeading
		// Start
		locationManager.startUpdatingHeading()
	}
}
