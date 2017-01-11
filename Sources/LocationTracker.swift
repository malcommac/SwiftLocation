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
	}
	
	/// Internal location manager reference
	private var locationManager: CLLocationManager
	
	/// Queued rewquests regarding location services
	private var locationObservers: [LocationRequest] = []
	
	/// This represent the status of the authorizations before a change
	private var lastStatus: CLAuthorizationStatus = CLAuthorizationStatus.notDetermined
	
	/// `true` to listen for application's state change from background to foreground and viceversa
	private var _listenForAppState: Bool = false
	private var listenForAppState: Bool {
		set {
			func disableNotifications() {
				 NotificationCenter.default.removeObserver(self)
			}
			func enableNotifications() {
				let center = NotificationCenter.default
				center.addObserver(self,
				                   selector:  #selector(applicationDidEnterBackground),
				                   name: NSNotification.Name.UIApplicationDidEnterBackground,
				                   object: nil)
				center.addObserver(self,
				                   selector:  #selector(applicationDidBecomeActive),
				                   name: NSNotification.Name.UIApplicationDidBecomeActive,
				                   object: nil)
			}
			guard _listenForAppState != newValue else {
				return
			}
			_listenForAppState = newValue
			disableNotifications()
			if newValue == true {
				enableNotifications()
			}
		}
		get {
			return _listenForAppState
		}
	}
	
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
			guard let settings = newValue else {
				locationManager.stopUpdatingLocation()
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.disallowDeferredLocationUpdates()
				_locationSettings = newValue
				return
			}
			
			if _locationSettings == newValue {
				return // ignore equal settings, avoid multiple sets
			}
			
			print("New settings: \(newValue)")
			_locationSettings = newValue
			// Set attributes for CLLocationManager instance
			locationManager.activityType = settings.activity // activity type (used to better preserve battery based upon activity)
			locationManager.desiredAccuracy = settings.accuracy.meters // accuracy (used to preserve battery based upon update frequency)
			if settings.frequency == .significant && CLLocationManager.significantLocationChangeMonitoringAvailable() {
				// If best frequency is significant location update (and hardware supports it) then start only significant location update
				locationManager.stopUpdatingLocation()
				locationManager.startMonitoringSignificantLocationChanges()
				locationManager.disallowDeferredLocationUpdates()
			} else if case .whenTravelled(let distance,let timeout) = settings.frequency {
				locationManager.stopMonitoringSignificantLocationChanges()
				locationManager.startUpdatingLocation()
				locationManager.allowDeferredLocationUpdates(untilTraveled: distance, timeout: timeout)
			} else {
				// Otherwise start full location manager services
				locationManager.stopMonitoringSignificantLocationChanges()
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
			return "Settings:\n -Accuracy: \(accuracy)\n -Frequency:\(frequency)\n -Activity:\(activity)"
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
			return (lhs.accuracy == rhs.accuracy && lhs.frequency == rhs.frequency && lhs.activity == rhs.activity)
		}
	}
	
	private var background: BackgroundTask = BackgroundTask()
	internal class BackgroundTask {
		var task: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
		var timer: Timer?
		
		func start() {
			let state = UIApplication.shared.applicationState
			if ((state == .background || state == .inactive) && task == UIBackgroundTaskInvalid) {
				self.runBackgroundTask(after: 20)
			}
		}
		
		func stop() {
			guard task != UIBackgroundTaskInvalid else { return }
			UIApplication.shared.endBackgroundTask(task)
			task = UIBackgroundTaskInvalid
		}
		
		private func runBackgroundTask(after time: TimeInterval) {
			let app = UIApplication.shared
			self.task = app.beginBackgroundTask(expirationHandler: { 
				app.endBackgroundTask(self.task)
				self.task = UIBackgroundTaskInvalid
			})
			
			DispatchQueue.global(qos: .userInitiated).async {
				self.timer?.invalidate()
				self.timer = Timer.scheduledTimer(timeInterval: time,
				                                  target: self,
				                                  selector: #selector(self.timeFired),
				                                  userInfo: nil,
				                                  repeats: false)
			}
		}
		
		@objc func timeFired() {
			let app = UIApplication.shared
			let remaining = app.backgroundTimeRemaining
			print("Remaining: \(remaining)")
			Location.updateLocationServices()
			self.runBackgroundTask(after: 5)
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
	
	@discardableResult
	public func getLocation(accuracy: Accuracy, frequency: Frequency, timeout: TimeInterval? = nil, success: @escaping LocationRequest.OnSuccessCallback, error: @escaping LocationRequest.OnErrorCallback) -> LocationRequest {
		
		let req = LocationRequest(accuracy: accuracy, frequency: frequency, success, error)
		req.timeout = timeout
		req.resume()
		return req
	}
	
	//MARK: Register/Unregister location requests
	
	/// Register a new request and enqueue it
	///
	/// - Parameter request: request to enqueue
	/// - Returns: `true` if added correctly to the queue, `false` otherwise.
	public func start<T: Request>(_ requests: T...) {
		var hasRegistrations = false
		for request in requests {
			if self.isQueued(request) == true {
				continue
			}
			
			if let request = request as? LocationRequest {
				self.locationObservers.append(request)
				hasRegistrations = true
			}
		}
		if hasRegistrations {
			self.updateLocationServices()
		}
	}
	
	
	/// Unregister and stops a queued request
	///
	/// - Parameter request: request to remove
	/// - Returns: `true` if request was removed successfully, `false` if it's not part of the queue
	public func cancel<T: Request>(_ requests: T...) {
		var hasUnregistrations = false
		for request in requests {
			if self.isQueued(request) == false { continue }
			
			if let request = request as? LocationRequest {
				locationObservers.remove(at: locationObservers.index(of: request)!)
				hasUnregistrations = true
			}
		}

		if hasUnregistrations == true {
			self.updateLocationServices()
		}
	}
	
	/// Return `true` if target `request` is part of a queue.
	///
	/// - Parameter request: target request
	/// - Returns: `true` if request is in a queue, `false` otherwise
	internal func isQueued<T: Request>(_ request: T?) -> Bool {
		guard let request = request else { return false }
		if let request = request as? LocationRequest {
			return locationObservers.contains(request)
		}
		return false
	}
	
	//MARK: Internal Location Manager Func
	
	/// Update location services based upon running Requests
	internal func updateLocationServices() {
		let hasBackgroundRequests = self.loc_hasBackgroundRequiredRequests()
		self.listenForAppState = hasBackgroundRequests

		let countRunning = locationObservers.reduce(0, { return $0 + ($1.state.isRunning ? 1 : 0) } )
		guard countRunning > 0 else {
			// There is not any running request, we can stop location service to preserve battery.
			locationManager.stopUpdatingLocation()
			locationManager.stopMonitoringSignificantLocationChanges()
			return
		}
		
		do {
			// Check if device supports location services.
			// If not dispatch the error to any running request and stop.
			guard CLLocationManager.locationServicesEnabled() else {
				locationObservers.forEach { $0.dispatchError(LocationError.serviceNotAvailable) }
				return
			}
			
			// Check if we need to require user authorization to use location services
			if try locationManager.requireAuthIfNeeded() == true {
				// If requested, show the system modal and put any running request in `.waitingUserAuth` status
				// then keep wait for any authorization status change
				self.loc_setRequestState(.waitingUserAuth, forRequestsIn: [.running,.idle])
				return
			}
			
			// If there is a request which needs background capabilities and we have not set it
			// dispatch proper error.
			if hasBackgroundRequests && CLLocationManager.isBackgroundUpdateEnabled == false {
				locationObservers.forEach { $0.dispatchError(LocationError.backgroundModeNotSet) }
				return
			}
			
			// Everything is okay we can setup CLLocationManager based upon the most accuracted/most frequent
			// Request queued and running.
			
			let isAppInBackground = (UIApplication.shared.applicationState == .background && CLLocationManager.isBackgroundUpdateEnabled)
			self.locationManager.allowsBackgroundLocationUpdates = isAppInBackground
			if isAppInBackground { self.autoPauseUpdates = false }
			
			// Resume any paused request (a paused request is in `.waitingUserAuth`,`.paused` or `.failed`)
			locationObservers.forEach { $0.resume() }
			// Evaluate best accuracy,frequency and activity type based upon all queued requests
			guard let bestSettings = self.loc_bestSettings() else {
				// No need to setup CLLocationManager, stop it.
				self.locationSettings = nil
				return
			}
			// Setup with best settings
			self.locationSettings = bestSettings
		} catch {
			// Something went wrong, stop all...
			self.locationSettings = nil
			// ... and dispatch error to any request
			locationObservers.forEach { $0.dispatchError(error) }
		}
	}
	
	private func loc_setRequestState(_ newState: RequestState, forRequestsIn states: Set<RequestState>) {
		locationObservers.forEach {
			if states.contains($0.state) {
				$0._state = newState
			}
		}
	}
	
	/// Return `true` if a running activity needs background capabilities, `false` otherwise
	///
	/// - Returns: boolean
	private func loc_hasBackgroundRequiredRequests() -> Bool {
		for request in self.locationObservers {
			if request.isBackgroundRequest {
				return true
			}
		}
		return false
	}
	
	/// Evaluate best settings based upon running location requests
	///
	/// - Returns: best settings
	private func loc_bestSettings() -> Settings? {
		guard locationObservers.count > 0 else {
			return nil // no settings, location manager can be disabled
		}
		
		var accuracy: Accuracy = locationObservers.first!.accuracy
		var frequency: Frequency = locationObservers.first!.frequency
		var type: CLActivityType = locationObservers.first!.activity
		
		for i in 1 ..< locationObservers.count {
			let request = locationObservers[i]
			guard request.state.isRunning else {
				continue // request is not running, can be ignored
			}
			
			if request.accuracy.rawValue < accuracy.rawValue {
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
	
	//MARK: Application State
	
	@objc func applicationDidEnterBackground() {
		self.updateRequestStateAccordingToAppState(true)
		self.background.start()
		self.updateLocationServices()
	}
	
	@objc func applicationDidBecomeActive() {
		self.updateRequestStateAccordingToAppState(false)
		self.background.stop()
		self.updateLocationServices()
	}
	
	/// Pause and Resume requests based upon their type (background/foreground based activities)
	///
	/// - Parameter isBackground: `true` if app is entering in background mode, `false` otherwise
	private func updateRequestStateAccordingToAppState(_ isBackground: Bool) {
		self.locationObservers.forEach {
			if isBackground == true {
				// when app is in background all foreground based request are paused
				// while any background request is resumed.
				if $0.isBackgroundRequest == false { $0.pause() }
				else { $0.resume() }
			} else {
				// viceversa when app is in foreground all background-based activities are
				// paused and foreground requests are resumed
				if $0.isBackgroundRequest == true { $0.pause() }
				else { $0.resume() }
			}
		}
		// Then unpdate the location manager based upon current settings
		self.updateLocationServices()
	}
	
	//MARK: CLLocationManager Delegate
	
	@objc open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		locationObservers.forEach { $0.dispatchAuthChange(self.lastStatus, status) }
		self.lastStatus = status
		
		switch status {
		case .denied, .restricted:
			locationObservers.forEach { $0.dispatchError(LocationError.authDidChange(status)) }
			self.updateLocationServices()
		case .authorizedAlways, .authorizedWhenInUse:
			locationObservers.forEach { $0.resume() }
			self.updateLocationServices()
		default:
			break
		}
	}
	
	@objc open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		locationObservers.forEach { $0.dispatchError(error) }
	}
	
	@objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.max(by: { (l1, l2) -> Bool in
			return l1.timestamp.timeIntervalSince1970 < l2.timestamp.timeIntervalSince1970}
			) else {
				return
		}
		print("\(Date())  -> \(location.horizontalAccuracy), \(location.coordinate.latitude), \(location.coordinate.longitude)")
		self.lastLocation.set(location: location)
		locationObservers.forEach { $0.dispatchLocation(location) }
	}
}
