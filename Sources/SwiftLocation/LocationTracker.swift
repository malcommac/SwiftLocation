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
import MapKit
import CoreLocation

/// Singleton instance for location tracker
public let Location = LocationTracker.shared

/// Location tracker class
public final class LocationTracker: NSObject, CLLocationManagerDelegate {

	public typealias RequestPoolDidChange = ((Any) -> (Void))
	public typealias LocationTrackerSettingsDidChange = ((TrackerSettings) -> (Void))
	public typealias LocationDidChange = ((CLLocation) -> (Void))
	
	/// This is a reference to LocationManager's singleton where the main queue for Requests.
	static let shared : LocationTracker = {
		// CLLocationManager must be created on main thread otherwise
		// it will generate an error at init time.
		if Thread.isMainThread {
			return LocationTracker()
		} else {
			return DispatchQueue.main.sync {
				return LocationTracker()
			}
		}
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
		var status = "Requests: \(countRunning)/\(countAll) (\(countPaused) paused)"
		if let settings = self.locationSettings {
			status += "\nSettings:\(settings)"
		} else {
			status += "\nSettings: services off"
		}
		return status
	}
	
	/// Callback called when a new request is added
	public var onAddNewRequest: RequestPoolDidChange? = nil
	
	/// Callback called when a request was removed
	public var onRemoveRequest: RequestPoolDidChange? = nil
	
	/// Called when location manager settings did change
	public var onChangeTrackerSettings: LocationTrackerSettingsDidChange? = nil
	
	/// On Receive new location
	public var onReceiveNewLocation: LocationDidChange? = nil
	
	/// Internal location manager reference
	internal var locationManager: CLLocationManager
	
	/// Queued requests regarding location services
	private var locationRequests: RequestsQueue<LocationRequest> = RequestsQueue()
	
	/// Queued requests regarding reverse geocoding services
	private var geocoderRequests: RequestsQueue<GeocoderRequest> = RequestsQueue()
	
	/// Queued requests regarding heading services
	private var headingRequests: RequestsQueue<HeadingRequest> = RequestsQueue()

	/// Queued requests regarding region monitor services
	private var regionRequests: RequestsQueue<RegionRequest> = RequestsQueue()
	
	/// Queued requests regarding visits
	private var visitRequests: RequestsQueue<VisitsRequest> = RequestsQueue()

	/// This represent the status of the authorizations before a change
	private var lastStatus: CLAuthorizationStatus = CLAuthorizationStatus.notDetermined
	
	/// `true` if location is deferred
	private(set) var isDeferred: Bool = false
	
	/// This represent the last locations received (best accurated location and last received location)
	public private(set) var lastLocation = LastLocation()
	
	/// Active CoreLocation settings based upon running requests
	private var _locationSettings: TrackerSettings?
	private(set) var locationSettings: TrackerSettings? {
		set {
			
			guard let settings = newValue else {
				locationManager.stopAllLocationServices()
				_locationSettings = newValue
				return
			}
			
			if _locationSettings == newValue {
				return // ignore equal settings, avoid multiple sets
			}
			
			_locationSettings = newValue
			// Set attributes for CLLocationManager instance
			locationManager.activityType = settings.activity // activity type (used to better preserve battery based upon activity)
			locationManager.desiredAccuracy = settings.accuracy.level // accuracy (used to preserve battery based upon update frequency)
			locationManager.distanceFilter = settings.distanceFilter
			
			self.onChangeTrackerSettings?(settings)

			switch settings.frequency {
			case .significant:
				guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
					locationManager.stopAllLocationServices()
					return
				}
				// If best frequency is significant location update (and hardware supports it) then start only significant location update
				locationManager.stopUpdatingLocation()
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.startMonitoringSignificantLocationChanges()
			case .deferredUntil(_,_,_):
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.startUpdatingLocation()
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
	
	// MARK: - Get location
	
	/// Create and enque a new location tracking request
	///
	/// - Parameters:
	///   - accuracy: accuracy of the location request (it may affect device's energy consumption)
	///   - frequency: frequency of the location retrive process (it may affect device's energy consumption)
	///   - timeout: optional timeout. If no location were found before timeout a `LocationError.timeout` error is reported.
	///   - success: success handler to call when a new location were found for this request
	///   - error: error handler to call when an error did occour while searching for request
	///	  - cancelOnError: if `true` request will be cancelled when first error is received (both timeout or location service error)
	/// - Returns: request
	@discardableResult
	public func getLocation(accuracy: Accuracy, frequency: Frequency, timeout: TimeInterval? = nil, cancelOnError: Bool = false, success: @escaping LocObserver.onSuccess, error: @escaping LocObserver.onError) -> LocationRequest {
		
		let req = LocationRequest(accuracy: accuracy, frequency: frequency, success, error)
		req.timeout = timeout
		req.cancelOnError = cancelOnError
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
	///	  - cancelOnError: if `true` request will be cancelled when first error is received (both timeout or location service error)
	///
	///   - success: success handler to call when reverse geocoding succeded
	///   - failure: failure handler to call when reverse geocoding fails
	/// - Returns: request
	@discardableResult
	public func getLocation(forAddress address: String, inRegion region: CLRegion? = nil, timeout: TimeInterval? = nil, cancelOnError: Bool = false, success: @escaping GeocoderObserver.onSuccess, failure: @escaping GeocoderObserver.onError) -> GeocoderRequest {
		let req = GeocoderRequest(address: address, region: region, success, failure)
		req.timeout = timeout
		req.cancelOnError = cancelOnError
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
	public func getPlacemark(forLocation location: CLLocation, timeout: TimeInterval? = nil,
	                        success: @escaping GeocoderObserver.onSuccess, failure: @escaping GeocoderObserver.onError) -> GeocoderRequest {
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
	@discardableResult
	public func getLocation(forABDictionary dict: [AnyHashable: Any], timeout: TimeInterval? = nil,
	                        success: @escaping GeocoderObserver.onSuccess, failure: @escaping GeocoderObserver.onError) -> GeocoderRequest {
		let req = GeocoderRequest(abDictionary: dict, success, failure)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	// MARK: - Get heading
	
	/// Allows you to receive heading update with a minimum filter degree
	///
	/// - Parameters:
	///   - filter: The minimum angular change (measured in degrees) required to generate new heading events.
	///	  - cancelOnError: if `true` request will be cancelled when first error is received (both timeout or location service error)
	///   - success: succss handler
	///   - failure: failure handler
	/// - Returns: request
	@discardableResult
	public func getContinousHeading(filter: CLLocationDegrees, cancelOnError: Bool = false,
	                                success: @escaping HeadingObserver.onSuccess, failure: @escaping HeadingObserver.onError) throws -> HeadingRequest {
		let request = try HeadingRequest(filter: filter, success: success, failure: failure)
		request.resume()
		request.cancelOnError = cancelOnError
		return request
	}
	
	// MARK: - Monitor geographic location

	/// Monitor a geographic region identified by a center coordinate and a radius.
	/// Region monitoring
	///
	/// - Parameters:
	///   - center: coordinate center
	///   - radius: radius in meters
	///	  - cancelOnError: if `true` request will be cancelled when first error is received (both timeout or location service error)
	///   - enter: callback for region enter event
	///   - exit: callback for region exit event
	///   - error: callback for errors
	/// - Returns: request
	/// - Throws: throw `LocationError.serviceNotAvailable` if hardware does not support region monitoring
	@discardableResult
	public func monitor(regionAt center: CLLocationCoordinate2D, radius: CLLocationDistance, cancelOnError: Bool = false,
	                    enter: RegionObserver.onEvent?, exit: RegionObserver.onEvent?, error: @escaping RegionObserver.onFailure) throws -> RegionRequest {
		let request = try RegionRequest(center: center, radius: radius, onEnter: enter, onExit: exit, error: error)
		request.resume()
		request.cancelOnError = cancelOnError
		return request
	}
	
	
	/// Monitor a specified region
	///
	/// - Parameters:
	///   - region: region to monitor
	///	  - cancelOnError: if `true` request will be cancelled when first error is received (both timeout or location service error)
	///   - enter: callback for region enter event
	///   - exit: callback for region exit event
	///   - error: callback for errors
	///   - error: callback for errors
	/// - Throws: throw `LocationError.serviceNotAvailable` if hardware does not support region monitoring
	@discardableResult
	public func monitor(region: CLCircularRegion, cancelOnError: Bool = false,
	                    enter: RegionObserver.onEvent?, exit: RegionObserver.onEvent?, error: @escaping RegionObserver.onFailure) throws -> RegionRequest {
		let request = try RegionRequest(region: region, onEnter: enter, onExit: exit, error: error)
		request.cancelOnError = cancelOnError
		request.resume()
		return request
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
	@discardableResult
	public func monitorVisit(event: @escaping VisitObserver.onVisit, error: @escaping VisitObserver.onFailure) throws -> VisitsRequest {
		let request = try VisitsRequest(event: event, error: error)
		request.resume()
		return request
	}
	
	//MARK: - Register/Unregister location requests
	
	/// Register a new request and enqueue it
	///
	/// - Parameter request: request to enqueue
	/// - Returns: `true` if added correctly to the queue, `false` otherwise.
	public func start<T: Request>(_ requests: T...) {
		var hasChanges = false
		for request in requests {
			
			// Location Requests
			if let request = request as? LocationRequest {
				request._state = .running
				if locationRequests.add(request) {
					hasChanges = true
				}
			}
			
			// Geocoder Requests
			if let request = request as? GeocoderRequest {
				request._state = .running
				if geocoderRequests.add(request) {
					hasChanges = true
				}
			}
			
			// Heading requests
			if let request = request as? HeadingRequest {
				request._state = .running
				if headingRequests.add(request) {
					hasChanges = true
				}
			}
			
			// Region Monitoring requests
			if let request = request as? RegionRequest {
				request._state = .running
				if regionRequests.add(request) {
					hasChanges = true
				}
			}
		}
		if hasChanges {
			requests.forEach { $0.onResume() }
			self.updateServicesStatus()
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
				locationRequests.remove(request)
				hasChanges = true
			}
			
			// Geocoder requests
			if let request = request as? GeocoderRequest {
				request._state = .idle
				geocoderRequests.remove(request)
				hasChanges = true
			}
			
			// Heading requests
			if let request = request as? HeadingRequest {
				request._state = .idle
				headingRequests.remove(request)
				hasChanges = true
			}
			
			// Region Monitoring requests
			if let request = request as? RegionRequest {
				request._state = .idle
				locationManager.stopMonitoring(for: request.region)
				regionRequests.remove(request)
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
			return locationRequests.isQueued(request)
		}
		
		// Geocoder Request
		if let request = request as? GeocoderRequest {
			return geocoderRequests.isQueued(request)
		}
		
		// Heading Request
		if let request = request as? HeadingRequest {
			return headingRequests.isQueued(request)
		}
		
		// Region Request
		if let request = request as? RegionRequest {
			return regionRequests.isQueued(request)
		}
		return false
	}
	
	//MARK: CLLocationManager Visits Delegate
	
	public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
		self.visitRequests.dispatch(value: visit)
	}
	
	//MARK: CLLocationManager Region Monitoring Delegate
	
	public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		let region = self.regionRequests.filter { $0.region == region }.first
		region?.onStartMonitoring?()
	}
	
	public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		let region = self.regionRequests.filter { $0.region == region }.first
		region?.dispatch(error: error)
	}
	
	public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		let region = self.regionRequests.filter { $0.region == region }.first
		region?.dispatch(event: .entered)
	}
	
	public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		let region = self.regionRequests.filter { $0.region == region }.first
		region?.dispatch(event: .exited)
	}
	
	public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
		let region = self.regionRequests.filter { $0.region == region }.first
		region?.dispatch(state: state)
	}
	
	//MARK: - Internal Heading Manager Func
	
	public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.headingRequests.dispatch(value: newHeading)
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
		locationRequests.forEach {
			if states.contains($0.state) {
				$0._state = newState
			}
		}
	}
	
	//MARK: - Deferred Location Helper Funcs
	
	private var isDeferredAvailable: Bool {
		// Seems `deferredLocationUpdatesAvailable()` function does not work properly in iOS 10
		// It's not clear if it's a bug or not.
		// Som elinks about the topic:
		// https://github.com/zakishaheen/deferred-location-implementation
		// http://stackoverflow.com/questions/39498899/deferredlocationupdatesavailable-returns-no-in-ios-10
		// https://github.com/lionheart/openradar-mirror/issues/15939
		//
		// Moreover activating deferred locations causes didFinishDeferredUpdatesWithError to be called with kCLErrorDeferredFailed
		if #available(iOS 10, *) {
			return true
		} else {
			return CLLocationManager.deferredLocationUpdatesAvailable()
		}
	}
	
	/// Evaluate deferred location best settings
	///
	/// - Returns: settings to apply
	private func deferredLocationSettings() -> (meters: Double, timeout: TimeInterval, accuracy: Accuracy)? {
		var meters: Double? = nil
		var timeout: TimeInterval? = nil
		var accuracyIsNavigation: Bool = false
		self.locationRequests.forEach {
			if case let .deferredUntil(rMt,rTime,rAcc) = $0.frequency {
				if meters == nil || (rMt < meters!) { meters = rMt }
				if timeout == nil || (rTime < timeout!) { timeout = rTime }
				if rAcc == true { accuracyIsNavigation = true }
			}
		}
		let accuracy = (accuracyIsNavigation ? Accuracy.navigation : Accuracy.room)
		return (meters == nil ? nil : (meters!,timeout!, accuracy))
	}
	
	
	/// Turn on and off deferred location updated if needed
	private func turnOnOrOffDeferredLocationUpdates() {
		// Turn on/off deferred location updates
		if let defSettings = deferredLocationSettings() {
			if self.isDeferred == false {
				locationManager.desiredAccuracy = defSettings.accuracy.level
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.pausesLocationUpdatesAutomatically = true
				locationManager.allowDeferredLocationUpdates(untilTraveled: defSettings.meters, timeout: defSettings.timeout)
				self.isDeferred = true
			}
		} else {
			if self.isDeferred {
				locationManager.disallowDeferredLocationUpdates()
				self.isDeferred = false
			}
		}
	}

	//MARK: - Location Tracking Helper Funcs
	
	/// Evaluate best settings based upon running location requests
	///
	/// - Returns: best settings
	private func locationTrackingBestSettings() -> TrackerSettings? {
		guard locationRequests.countRunning > 0 else {
			return nil // no settings, location manager can be disabled
		}
		
		var accuracy: Accuracy = .any
		var frequency: Frequency = .significant
		var type: CLActivityType = .other
		var distanceFilter: CLLocationDistance? = kCLDistanceFilterNone
		
		for request in locationRequests {
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
			if request.minimumDistance == nil {
				// If mimumDistance is nil it's equal to `kCLDistanceFilterNone` and it will
				// reports all movements regardless measured distance
				distanceFilter = nil
			} else {
				// Otherwise if distanceFilter is higher than `kCLDistanceFilterNone` and our value is less than
				// the current value, we want to store it. Lower value is the setting.
				if distanceFilter != nil && request.minimumDistance! < distanceFilter! {
					distanceFilter = request.minimumDistance!
				}
			}
		}
		
		if distanceFilter == nil {
			// translate it to the right value. `kCLDistanceFilterNone` report all movements
			// regardless the horizontal distance measured.
			distanceFilter = kCLDistanceFilterNone
		}
		
		// Deferred location updates
		// Because deferred updates use the GPS to track location changes,
		// the location manager allows deferred updates only when GPS hardware
		// is available on the device and when the desired accuracy is set to kCLLocationAccuracyBest
		// or kCLLocationAccuracyBestForNavigation.
		// - A) If the GPS hardware is not available, the location manager reports a deferredFailed error.
		// - B) If the accuracy is not set to one of the supported values, the location manager reports a deferredAccuracyTooLow error.
		// - C) In addition, the distanceFilter property of the location manager must be set to kCLDistanceFilterNone.
		// If it is set to any other value, the location manager reports a deferredDistanceFiltered error.
		if isDeferredAvailable, let deferredSettings = self.deferredLocationSettings() { // has any deferred location request
			accuracy = deferredSettings.accuracy // B)
			distanceFilter = kCLDistanceFilterNone // C)
			let isNavigationAccuracy = (deferredSettings.accuracy.level == kCLLocationAccuracyBestForNavigation)
			frequency = .deferredUntil(distance: deferredSettings.meters, timeout: deferredSettings.timeout, navigation:  isNavigationAccuracy)
		}
		
		return TrackerSettings(accuracy: accuracy, frequency: frequency, activity: type, distanceFilter: distanceFilter!)
	}

	//MARK: - CLLocationManager Location Tracking Delegate
	
	@objc open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		locationRequests.forEach { $0.dispatchAuthChange(self.lastStatus, status) }
		self.lastStatus = status
		
		switch status {
		case .denied, .restricted:
			let error = LocationError.authDidChange(status)
			self.pools.forEach { $0.dispatch(error: error) }
			self.updateServicesStatus()
		case .authorizedAlways, .authorizedWhenInUse:
			self.pools.forEach { $0.resumeWaitingAuth() }
			self.updateServicesStatus()
		default:
			break
		}
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else {
			return
		}
		self.onReceiveNewLocation?(location)
		
		// Note:
		// We need to start the deferred location delivery (by calling allowDeferredLocationUpdates) after
		// the first location is arrived. So if this is the first location we have received and we have
		// running deferred location request we can start it.
		if self.lastLocation.last != nil {
			turnOnOrOffDeferredLocationUpdates()
		}
		
		// Store last location
		self.lastLocation.set(location: location)
		
		// Dispatch to any request (which is not of type deferred)
		locationRequests.iterate({ return ($0.frequency.isDeferredFrequency == false) }, {
			$0.dispatch(location: location)
		})
	}
	
	//MARK: CLLocationManager Deferred Error Delegate

	public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
		// iterate over deferred locations
		locationRequests.iterate({ return $0.frequency.isDeferredFrequency }, {
			$0.dispatch(error: error ?? LocationError.unknown)
		})
	}
	
	//MARK: CLLocationManager Error Delegate
	
	@objc open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		locationRequests.iterate({ return $0.frequency.isDeferredFrequency }, {
			$0.dispatch(error: error)
		})
	}
	
	//MARK: - Update Services Status
	
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
	
	private var pools: [RequestsQueueProtocol] {
		let pools: [RequestsQueueProtocol] = [locationRequests, regionRequests, visitRequests,geocoderRequests,headingRequests]
		return pools
	}
	
	/// Require authorizations if needed
	///
	/// - Returns: `true` if authorization is needed, `false` otherwise
	/// - Throws: throw if some required settings are missing
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
	
	// MARK: - Services Update
	
	/// Update visiting services
	internal func updateVisitsServices() {
		guard visitRequests.countRunning > 0 else {
			// There is not any running request, we can stop monitoring all regions
			locationManager.stopMonitoringVisits()
			return
		}
		locationManager.startMonitoringVisits()
	}
	
	/// Update location services based upon running Requests
	internal func updateLocationServices() {
		let hasBackgroundRequests = locationRequests.hasBackgroundRequests()
		
		guard locationRequests.countRunning > 0 else {
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
		
		print("Settings \(bestSettings)")
		
		// Request authorizations if needed
		if bestSettings.accuracy.requestUserAuth == true {
			// Check if device supports location services.
			// If not dispatch the error to any running request and stop.
			guard CLLocationManager.locationServicesEnabled() else {
				locationRequests.forEach { $0.dispatch(error: LocationError.serviceNotAvailable) }
				return
			}
		}
		
		// If there is a request which needs background capabilities and we have not set it
		// dispatch proper error.
		if hasBackgroundRequests && CLLocationManager.isBackgroundUpdateEnabled == false {
			locationRequests.forEach { $0.dispatch(error: LocationError.backgroundModeNotSet) }
			return
		}
		
		// Everything is okay we can setup CLLocationManager based upon the most accuracted/most frequent
		// Request queued and running.
		
		let isAppInBackground = (UIApplication.shared.applicationState == .background && CLLocationManager.isBackgroundUpdateEnabled)
		self.locationManager.allowsBackgroundLocationUpdates = isAppInBackground
		if isAppInBackground { self.autoPauseUpdates = false }
		
		// Resume any paused request (a paused request is in `.waitingUserAuth`,`.paused` or `.failed`)
		locationRequests.iterate([.waitingUserAuth]) { $0.resume() }
		
		// Setup with best settings
		self.locationSettings = bestSettings
	}
	
	
	internal func updateRegionMonitoringServices() {
		// Region monitoring is not available for this hardware
		guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
			regionRequests.dispatch(error: LocationError.serviceNotAvailable)
			return
		}
		
		// Region monitoring require always authorizaiton, if not generate error
		let auth = CLLocationManager.appAuthorization
		if auth != .always && auth != .both {
			regionRequests.dispatch(error: LocationError.requireAlwaysAuth)
			return
		}
		
		guard regionRequests.countRunning > 0 else {
			// There is not any running request, we can stop monitoring all regions
			locationManager.stopMonitoringAllRegions()
			return
		}
		
		// Monitor queued regions
		regionRequests.forEach {
			if $0.state.isRunning {
				locationManager.startMonitoring(for: $0.region)
			}
		}
	}
	
	/// Update heading services
	internal func updateHeadingServices() {
		// Heading service is not available on current hardware
		guard CLLocationManager.headingAvailable() else {
			self.headingRequests.dispatch(error: LocationError.serviceNotAvailable)
			return
		}
		
		guard headingRequests.countRunning > 0 else {
			// There is not any running request, we can stop location service to preserve battery.
			locationManager.stopUpdatingHeading()
			return
		}
		
		// Find max accuracy in reporting heading and set it
		var bestHeading: CLLocationDegrees = Double.infinity
		for request in headingRequests {
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
