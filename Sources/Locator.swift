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

/// Shortcut to locator manager
public let Locator: LocatorManager = LocatorManager.shared

/// The main class responsibile of location services
public class LocatorManager: NSObject, CLLocationManagerDelegate {
	
	// MARK: PROPERTIES

	public class APIs {
		
		/// Google API key
		public var googleAPIKey: String?
		
	}
	
	public class Events {
		
		public typealias Token = UInt64
		
		/// Token
		private var nextTokenID: Token = 0
		
		/// Did Change Auth Closure type
		public typealias AuthorizationDidChangeEvent = ((CLAuthorizationStatus) -> (Void))
		
		/// Listeners of auth status change
		internal var callbacks: [Token : AuthorizationDidChangeEvent] = [:]
	
		/// Add a listener for authorization change status
		///
		/// - Parameter callback: callback to call
		/// - Returns: token used to remove the listener in a second time.
		public func listen(forAuthChanges callback: @escaping AuthorizationDidChangeEvent) -> Token {
			var (next,overflow) = self.nextTokenID.addingReportingOverflow(1)
			if overflow {
				next = 0
			}
			self.callbacks[next] = callback
			return next
		}
		
		/// Remove listener from token.
		///
		/// - Parameter token: token
		/// - Returns: `true` if removed, `false` otherwise
		@discardableResult
		public func remove(token: Token) -> Bool {
			return (self.callbacks.removeValue(forKey: token) != nil)
		}
		
		/// Remove all registered listeners.
		public func removeAll() {
			self.callbacks.removeAll()
		}
	}
	
	/// Events listener
	public private(set) var events: Events = Events()
	
	/// Api key for helper services
	public private(set) var api = APIs()
	
	/// Shared instance of the location manager
	internal static let shared = LocatorManager()
	
	/// Core location internal manager
	internal var manager: CLLocationManager
	
	/// Current queued location requests
	private var locationRequests = SafeList<LocationRequest>()
	
	/// Current queued heading requests
	private var headingRequests = SafeList<HeadingRequest>()
	
	/// Geocoder requests
	internal var geocoderRequests = SafeList<GeocoderRequest>()
	
	/// Ip requests
	internal var ipLocationRequests = SafeList<IPLocationRequest>()

	/// `true` if service is currently updating current location
	public private(set) var isUpdatingLocation: Bool = false
	
	/// `true` if service is currently updating current heading
	public private(set) var isUpdatingHeading: Bool = false
	
	/// `true` if service is currenlty monitoring significant location changes
	public private(set) var isMonitoringSignificantLocationChanges = false
	
	/// It is possible to force enable background location fetch even if your set any kind of Authorizations
	public var backgroundLocationUpdates: Bool {
		set { self.manager.allowsBackgroundLocationUpdates = true }
		get { return self.manager.allowsBackgroundLocationUpdates }
	}
	
	/// Current authorization status of the location manager
	public var authorizationStatus: CLAuthorizationStatus {
		return CLLocationManager.authorizationStatus()
	}
	
	/// Returns the most recent current location, or nil if the current
	/// location is unknown, invalid, or stale.
	private var _currentLocation: CLLocation? = nil
	public var currentLocation: CLLocation? {
		guard let l = self._currentLocation else {
			return nil
		}
		// invalid coordinates, discard id
		if (!CLLocationCoordinate2DIsValid(l.coordinate)) ||
			(l.coordinate.latitude == 0.0 || l.coordinate.longitude == 0.0) {
			return nil
		}
		return l
	}
	
	/// Last measured heading value
	public private(set) var currentHeading: CLHeading? = nil
	
	/// Last occurred error
	public private(set) var updateFailed: Bool = false
	
	/// Returns the current state of location services for this app,
	/// based on the system settings and user authorization status.
	public var state: ServiceState {
		return self.manager.serviceState
	}
	
	/// Return the current accuracy level of the location manager
	/// This value is managed automatically based upon current queued requests
	/// in order to better manage power consumption.
	public private(set) var accuracy: Accuracy {
		get { return Accuracy(self.manager.desiredAccuracy) }
		set {
			if self.manager.desiredAccuracy != newValue.threshold {
				self.manager.desiredAccuracy = newValue.threshold
			}
		}
	}
	
	private override init() {
		self.manager = CLLocationManager()
		super.init()
		self.manager.delegate = self
		
		// iOS 9 requires setting allowsBackgroundLocationUpdates to true in order to receive
		// background location updates.
		// We only set it to true if the location background mode is enabled for this app,
		// as the documentation suggests it is a fatal programmer error otherwise.
		if #available(iOSApplicationExtension 9.0, *) {
			if CLLocationManager.hasBackgroundCapabilities {
				self.manager.allowsBackgroundLocationUpdates = true
			}
		}
	}
	
	// MARK: CURRENT LOCATION FUNCTIONS

	/// Asynchronously requests the current location of the device using location services,
	/// optionally waiting until the user grants the app permission
	/// to access location services before starting the timeout countdown.
	///
	/// - Parameters:
	///   - accuracy: The accuracy level desired (refers to the accuracy and recency of the location).
	///   - timeout: the amount of time to wait for a location with the desired accuracy before completing.
	///   - onUpdate: update callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
	public func currentPosition(accuracy: Accuracy, timeout: Timeout? = nil,
	                            onSuccess: @escaping LocationRequest.Success, onFail: @escaping LocationRequest.Failure) -> LocationRequest {
	//	assert(Thread.isMainThread, "Locator functions should be called from main thread")
		let request = LocationRequest(mode: .oneshot, accuracy: accuracy.validateForGPSRequest, timeout: timeout)
		request.success = onSuccess
		request.failure = onFail
		// Start timer if needs to be started (not delayed and valid timer)
		request.timeout?.startTimeout(force: false)
		// Append to the queue
		self.addLocation(request)
		return request
	}
	
	/// Get the current position using the IP address of the device (one shot).
	/// Location is not very accurate but it does not require user authorizations.
	///
	/// - Parameters:
	///   - usingIP: IP address
	///   - timeout: timeout interval
	///   - onSuccess: success callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
	public func currentPosition(usingIP service: IPService, timeout: TimeInterval? = nil,
	                            onSuccess: @escaping LocationRequest.Success, onFail: @escaping LocationRequest.Failure) -> IPLocationRequest {
		let request = IPLocationRequest(service, timeout: timeout)
		self.ipLocationRequests.add(request)
		request.success = onSuccess
		request.failure = onFail
		// execute
		request.execute()
		return request
	}

	/// Creates a subscription for location updates that will execute the block once per update
	/// indefinitely (until canceled), regardless of the accuracy of each location.
	/// This method instructs location services to use the highest accuracy available
	/// (which also requires the most power).
	/// If an error occurs, the block will execute with a status other than INTULocationStatusSuccess,
	/// and the subscription will be canceled automatically.
	///
	/// - Parameters:
	///   - accuracy: The accuracy level desired (refers to the accuracy and recency of the location).
	///   - onUpdate: update callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
	public func subscribePosition(accuracy: Accuracy,
	                              onUpdate: @escaping LocationRequest.Success, onFail: @escaping LocationRequest.Failure) -> LocationRequest {
		assert(Thread.isMainThread, "Locator functions should be called from main thread")
		let request = LocationRequest(mode: .continous, accuracy: accuracy.validateForGPSRequest, timeout: nil)
		request.success = onUpdate
		request.failure = onFail
		// Append to the queue
		self.addLocation(request)
		return request
	}
	
	/// Creates a subscription for significant location changes that will execute the
	/// block once per change indefinitely (until canceled).
	/// If an error occurs, the block will execute with a status other than INTULocationStatusSuccess,
	/// and the subscription will be canceled automatically.
	///
	/// - Parameters:
	///   - onUpdate: update callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
	public func subscribeSignificantLocations(onUpdate: @escaping LocationRequest.Success, onFail: @escaping LocationRequest.Failure) -> LocationRequest {
		assert(Thread.isMainThread, "Locator functions should be called from main thread")
		let request = LocationRequest(mode: .significant, accuracy: .any, timeout: nil)
		request.success = onUpdate
		request.failure = onFail
		// Append to the queue
		self.addLocation(request)
		return request
	}
	
	// MARK: REVERSE GEOCODING
	
	/// Get the location from address string and return a `CLLocation` object.
	/// Request is started automatically.
	///
	/// - Parameters:
	///   - address: address string or place to search
	///   - region: A geographical region to use as a hint when looking up the specified address. Specifying a region lets you prioritize
	/// 			the returned set of results to locations that are close to some specific geographical area, which is typically
	///				the user’s current location. It's valid only if you are using apple services.
	///   - service: service to use, `nil` to user apple's built in service
	///   - timeout: timeout interval, if `nil` 10 seconds timeout is used
	///   - onSuccess: callback called on success
	///   - onFail: callback called on failure
	/// - Returns: request
	@discardableResult
	public func location(fromAddress address: String, in region: CLRegion? = nil,
	                     using service: GeocoderService? = nil, timeout: TimeInterval? = nil,
	                     onSuccess: @escaping GeocoderRequest_Success, onFail: @escaping GeocoderRequest_Failure) -> GeocoderRequest {
		let request = (service ?? .apple).newRequest(operation: .getLocation(address: address, region: region), timeout: timeout)
		self.geocoderRequests.add(request)
		request.success = onSuccess
		request.failure = onFail
		request.execute()
		return request
	}

	/// Get the location data from given coordinates.
	/// Request is started automatically.
	///
	/// - Parameters:
	///   - coordinates: coordinates to search
	///   - locale: The locale to use when returning the address information. You might specify a value for this parameter when you want the address returned in a locale that differs from the user's current language settings. Specify nil to use the user's default locale information. It's valid only if you are using apple services.
	///   - service: service to use, `nil` to user apple's built in service
	///   - onSuccess: callback called on success
	///   - onFail: callback called on failure
	///   - timeout: timeout interval, if `nil` 10 seconds timeout is used
	///   - timeout: timeout interval, if `nil` 10 seconds timeout is used
	@discardableResult
	public func location(fromCoordinates coordinates: CLLocationCoordinate2D, locale: Locale? = nil,
	                     using service: GeocoderService? = nil, timeout: TimeInterval? = nil,
	                     onSuccess: @escaping GeocoderRequest_Success, onFail: @escaping GeocoderRequest_Failure) -> GeocoderRequest {
		let request = (service ?? .apple).newRequest(operation: .getPlace(coordinates: coordinates, locale: locale), timeout: timeout)
		self.geocoderRequests.add(request)
		request.success = onSuccess
		request.failure = onFail
		request.execute()
		return request
	}

	// MARK: AUTOCOMPLETE PLACES & DETAILS
	
	/// Autocomplete places from input string. It uses Google Places API for Autocomplete.
	/// In order to use it you must obtain a free api key and set it to `Locator.apis.googleApiKey` property
	///
	/// - Parameters:
	///   - text: text to search
	///   - timeout: timeout, `nil` uses default 10-seconds timeout interval
	///   - onSuccess: success callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
    public func autocompletePlaces(with text: String, timeout: TimeInterval? = nil, language: FindPlaceRequest_Google_Language? = nil,
	                         onSuccess: @escaping FindPlaceRequest_Success, onFail: @escaping FindPlaceRequest_Failure) -> FindPlaceRequest {
        let request = FindPlaceRequest_Google(input: text, timeout: timeout, language: language)
		request.success = onSuccess
		request.failure = onFail
		request.execute()
		return request
	}
	
	// MARK: DEVICE HEADING FUNCTIONS
	
	/// Asynchronously requests the current heading of the device using location services.
	/// The current heading (the most recent one acquired, regardless of accuracy level),
	/// or nil if no valid heading was acquired
	///
	/// - Parameters:
	///   - accuracy: minimum accuracy you want to receive. `nil` to receive all events
	///   - minInterval: minimum interval between each request. `nil` to receive all events regardless the interval.
	///   - onUpdate: update succeded callback
	///   - onFail: failure callback
	/// - Returns: request
	@discardableResult
	public func subscribeHeadingUpdates(accuracy: HeadingRequest.AccuracyDegree?, minInterval: TimeInterval? = nil,
	                                    onUpdate: @escaping HeadingRequest.Success, onFail: @escaping HeadingRequest.Failure) -> HeadingRequest {
		// Create request
		let request = HeadingRequest(accuracy: accuracy, minInterval: minInterval)
		request.success = onUpdate
		request.failure = onFail
		// Append it
		self.addHeadingRequest(request)
		return request
	}
	
	/// Stop running request
	///
	/// - Parameter request: request to stop
	@discardableResult
	public func stopRequest(_ request: Request) -> Bool {
		if let r = request as? LocationRequest {
			return self.stopLocationRequest(r)
		}
		if let r = request as? HeadingRequest {
			return self.stopHeadingRequest(r)
		}
		return false
	}
	
	/// HEADING HELPER FUNCTIONS

	/// Add heading request to queue
	///
	/// - Parameter request: request
	private func addHeadingRequest(_ request: HeadingRequest) {
		let state = self.manager.headingState
		guard state == .available else {
			DispatchQueue.main.async {
				request.failure?(state)
			}
			return
		}
		
		self.headingRequests.add(request)
		self.startUpdatingHeadingIfNeeded()
	}
	
	/// Start updating heading service if needed
	private func startUpdatingHeadingIfNeeded() {
		guard self.headingRequests.count > 0 else { return }
		self.manager.startUpdatingHeading()
		self.isUpdatingHeading = true
	}
	
	/// Stop heading services if possible
	private func stopUpdatingHeadingIfPossible() {
		if self.headingRequests.count == 0 {
			self.manager.stopUpdatingHeading()
			self.isUpdatingHeading = false
		}
	}
	
	
	/// Remove heading request
	///
	/// - Parameter request: request to remove
	/// - Returns: `true` if removed
	@discardableResult
	private func stopHeadingRequest(_ request: HeadingRequest) -> Bool {
		let removed = self.headingRequests.remove(request)
		self.stopUpdatingHeadingIfPossible()
		return removed
	}
	
	// MARK: LOCATION HELPER FUNCTIONS
	
	/// Stop location request
	///
	/// - Parameter request: request
	/// - Returns: `true` if request is removed
	@discardableResult
	private func stopLocationRequest(_ request: LocationRequest?) -> Bool {
		guard let r = request else { return false }
		
		if r.isRecurring { // Recurring requests can only be canceled
			r.timeout?.abort()
			self.locationRequests.remove(r)
		} else {
			r.timeout?.forceTimeout() // force timeout
			self.completeLocationRequest(r) // complete request
		}
		return true
	}
	
	/// Adds the given location request to the array of requests, updates
	/// the maximum desired accuracy, and starts location updates if needed.
	///
	/// - Parameter request: request to add
	private func addLocation(_ request: LocationRequest) {
		/// No need to add this location request, because location services are turned off device-wide,
		/// or the user has denied this app permissions to use them.
		guard self.manager.servicesAreAvailable else {
			self.completeLocationRequest(request)
			return
		}
		
		switch request.mode {
		case .oneshot, .continous:
			// Determine the maximum desired accuracy for all existing location requests including the new one
			let maxAccuracy = self.maximumAccuracyInQueue(andRequest: request)
			self.accuracy = maxAccuracy
			
			self.startUpdatingLocationIfNeeded()
		case .significant:
			self.startMonitoringSignificantLocationChangesIfNeeded()
		}
		
		// Add to the queue
		self.locationRequests.add(request)
		// Process all location requests now, as we may be able to immediately
		// complete the request just added above
		// If a location update was recently received (stored in self.currentLocation)
		// that satisfies its criteria.
	}
	
	/// Return the max accuracy between the current queued requests and another request
	///
	/// - Parameter request: request, `nil` to compare only queued requests
	/// - Returns: max accuracy detail
	private func maximumAccuracyInQueue(andRequest request: LocationRequest? = nil) -> Accuracy {
		let maxAccuracy: Accuracy = self.locationRequests.list.map { $0.accuracy }.reduce(request?.accuracy ?? .any) { max($0,$1) }
		return maxAccuracy
	}
	
	internal func locationRequestDidTimedOut(_ request: LocationRequest) {
		if let _ = self.locationRequests.index(of: request) {
			self.completeLocationRequest(request)
		}
	}
	
	internal func startUpdatingLocationIfNeeded() {
		// Request authorization if not set yet
		self.requestAuthorizationIfNeeded()
		
		let requests = self.activeLocationRequest(excludingMode: .significant)
		if requests.count == 0 {
			self.manager.startUpdatingLocation()
			self.isUpdatingLocation = true
		}
	}
	
	/// Inform CLLocationManager to start monitoring significant location changes.
	internal func startMonitoringSignificantLocationChangesIfNeeded() {
		// request authorization if needed
		self.requestAuthorizationIfNeeded()
		
		let requests = self.activeLocationRequest(forMode: .significant)
		if requests.count == 0 {
			self.manager.startMonitoringSignificantLocationChanges()
			self.isMonitoringSignificantLocationChanges = true
		}
		
	}
	
	/// Return active requests excluding the one with given mode
	///
	/// - Parameter mode: mode
	/// - Returns: filtered list
	private func activeLocationRequest(excludingMode mode: LocationRequest.Mode) -> [LocationRequest] {
		return self.locationRequests.list.filter { $0.mode != mode }
	}
	
	/// Return active request of the given type
	///
	/// - Parameter mode: type to get
	/// - Returns: filtered list
	private func activeLocationRequest(forMode mode: LocationRequest.Mode) -> [LocationRequest] {
		return self.locationRequests.list.filter { $0.mode == mode }
	}

	/// As of iOS 8, apps must explicitly request location services permissions.
	/// SwiftLocation supports both levels, "Always" and "When In Use".
	/// If not called directly this function is called when the first enqueued request is added to the list.
	/// In this case SwiftLocation determines which level of permissions to request based on which description
	/// key is present in your app's Info.plist (If you provide values for both description keys,
	/// the more permissive "Always" level is requested.).
	/// If you need to set the authorization manually be sure to call this function before adding any request.
	///
	/// - Parameter type: authorization level, `nil` to use internal deterministic algorithm
	public func requestAuthorizationIfNeeded(_ type: AuthorizationLevel? = nil) {
		let currentAuthLevel = CLLocationManager.authorizationStatus()
		guard currentAuthLevel == .notDetermined else { return } // already authorized
		
		// Level to set is the one passed as argument or, if value is `nil`
		// is determined by reading values in host application's Info.plist
		let levelToSet = type ?? CLLocationManager.authorizationLevelFromInfoPlist
		self.manager.requestAuthorization(level: levelToSet)
	}
	
	// Iterates over the array of active location requests to check and see
	// if the most recent current location successfully satisfies any of their criteria so we
	// can return it without waiting for a new fresh value.
	private func processLocationRequests() {
		let location = self.currentLocation
		self.locationRequests.list.forEach {
			if $0.timeout?.hasTimedout ?? false {
				// Non-recurring request has timed out, complete it
				$0.location = location
				self.completeLocationRequest($0)
			} else {
				if let mostRecent = location {
					if $0.isRecurring {
						// This is a subscription request, which lives indefinitely
						// (unless manually canceled) and receives every location update we get.
						$0.location = location
						self.processRecurringRequest($0)
					} else {
						// This is a regular one-time location request
						if $0.hasValidThrehsold(forLocation: mostRecent) {
							// The request's desired accuracy has been reached, complete it
							$0.location = location
							self.completeLocationRequest($0)
						}
					}
				}
			}
		}
	}
	
	/// Immediately completes all active location requests.
	/// Used in cases such as when the location services authorization
	/// status changes to `.denied` or `.restricted`.
	public func completeAllLocationRequests() {
		let activeRequests = self.locationRequests
		activeRequests.list.forEach {
			self.completeLocationRequest($0)
		}
	}
	
	/// Complete passed location request and remove from queue if possible.
	///
	/// - Parameter request: request
	public func completeLocationRequest(_ request: LocationRequest?) {
		guard let r = request else { return }
		
		r.timeout?.abort() // stop any running timer
		self.removeLocationRequest(r) // remove from queue
		
		// SwiftLocation is not thread safe and should only be called from the main thread,
		// so we should already be executing on the main thread now.
		// DispatchQueue.main.async() is used to ensure that the completion block for a request
		// is not executed before the request ID is returned, for example in the
		// case where the user has denied permission to access location services and the request
		// is immediately completed with the appropriate error.
		DispatchQueue.main.async {
			if let error = r.error { // failed for some sort of error
				r.failure?(error,r.location)
			} else if let loc = r.location { // succeded
				r.success?(loc)
			}
		}
	}
	
	/// Handles calling a recurring location request's block with the current location.
	///
	/// - Parameter request: request
	private func processRecurringRequest(_ request: LocationRequest?) {
		guard let r = request, r.isRecurring else { return } // should be called by valid recurring request
		
		DispatchQueue.main.async {
			if let error = r.error {
				r.failure?(error,r.location)
			} else if let loc = r.location {
				r.success?(loc)
			}
		}
	}
	
	/// Removes a given location request from the array of requests,
	/// updates the maximum desired accuracy, and stops location updates if needed.
	///
	/// - Parameter request: request to remove
	private func removeLocationRequest(_ request: LocationRequest?) {
		guard let r = request else { return }
		self.locationRequests.remove(r)
		
		switch r.mode {
		case .oneshot, .continous:
			// Determine the maximum desired accuracy for all remaining location requests
			let maxAccuracy = self.maximumAccuracyInQueue()
			self.accuracy = maxAccuracy
			// Stop if no other location requests are running
			self.stopUpdatingLocationIfPossible()
		case .significant:
			self.stopMonitoringSignificantLocationChangesIfPossible()
		}
	}
	
	/// Checks to see if there are any outstanding locationRequests,
	/// and if there are none, informs CLLocationManager to stop sending
	/// location updates. This is done as soon as location updates are no longer
	/// needed in order to conserve the device's battery.
	private func stopUpdatingLocationIfPossible() {
		let requests = self.activeLocationRequest(excludingMode: .significant)
		if requests.count == 0 { // can be stopped
			self.manager.stopUpdatingLocation()
			self.isUpdatingLocation = false
		}
	}
	
	/// Checks to see if there are any outsanding significant location request in queue.
	/// If not we can stop monitoring for significant location changes and conserve device's battery.
	private func stopMonitoringSignificantLocationChangesIfPossible() {
		let requests = self.activeLocationRequest(forMode: .significant)
		if requests.count == 0 { // stop
			self.manager.stopMonitoringSignificantLocationChanges()
			self.isMonitoringSignificantLocationChanges = false
		}
	}
	
	// MARK: CLLocationManager Delegates
	
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
	 	// Clear any previous errors
		self.updateFailed = false
		
		// Store last data
		let recentLocations = locations.min(by: { (a, b) -> Bool in
			return a.timestamp.timeIntervalSinceNow < b.timestamp.timeIntervalSinceNow
		})
		self._currentLocation = recentLocations
		
		// Process the location requests using the updated location
		self.processLocationRequests()
	}
	
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		self.updateFailed = true // an error has occurred
		
		self.locationRequests.list.forEach {
			if $0.isRecurring { // Keep the recurring request alive
				self.processRecurringRequest($0)
			} else { // Fail any non-recurring requests
				self.completeLocationRequest($0)
			}
		}
	}
	
	public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

		// Alert any listener
		self.events.callbacks.values.forEach { $0(status) }
		guard status != .denied && status != .restricted else {
			// Clear out any active location requests (which will execute the blocks
			// with a status that reflects
			// the unavailability of location services) since we now no longer have
			// location services permissions
			self.completeAllLocationRequests()
			return
		}
		
		if status == .authorizedAlways || status == .authorizedWhenInUse {
			self.locationRequests.list.forEach({
				// Start the timeout timer for location requests that were waiting for authorization
				$0.timeout?.startTimeout()
			})
		}
	}
	
	public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		self.currentHeading = newHeading
		self.processRecurringHeadingRequests()
	}
	
	private func processRecurringHeadingRequests() {
		let h = self.currentHeading
		DispatchQueue.main.async {
			self.headingRequests.list.forEach { r in
				if r.isValidHeadingForRequest(h) {
					r.heading = h
				}
				if let err = r.error {
					r.failure?(err)
					self.stopHeadingRequest(r)
				} else {
					r.success?(r.heading!)
				}
			}
		}
	}
}
