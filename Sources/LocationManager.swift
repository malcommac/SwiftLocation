//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import CoreLocation

/// LocationManager is the class used to manage each request.
public class LocationManager: NSObject {
    
    // MARK: - Public Typealiases -
    
    public typealias RequestID = String
    internal typealias LocationRequestSet = Set<LocationRequest>
    internal typealias GeocoderRequestSet = Set<GeocoderRequest>
    internal typealias AutocompleteRequestSet = Set<AutoCompleteRequest>
    internal typealias IPRequestSet = Set<LocationByIPRequest>
    internal typealias HeadingRequestSet = Set<HeadingRequest>
    
    public typealias QueueChange = ((_ added: Bool, _ request: ServiceRequest) -> Void)
    public typealias AuthorizationChange = ((State) -> Void)

    // MARK: - Public Properties -
    
    /// This is the singleton to manage location manager subscriptions.
    public static let shared = LocationManager()
    
    /// Return the current authorization state.
    public static var state: State {
        switch (CLLocationManager.locationServicesEnabled(), CLLocationManager.authorizationStatus()) {
        case (false,_):
            return .disabled
        case (true, .notDetermined):
            return .undetermined
        case (true, .denied):
            return .denied
        case (true, .restricted):
            return .restricted
        default:
            return .available
        }
    }
    
    /// Timeout interval used as default value for each new request.
    /// By default is set to `15` seconds.
    public var timeout: TimeInterval = 15
    
    /// Identify the preferred authorization mode the library can use
    /// to request user permissions. By default it's set to `viaInfoPList` and
    /// it will use whenInUse/always based upon the keys presents into that file.
    public var preferredAuthorization: CLLocationManager.AuthorizationMode = .viaInfoPlist
    
    /// Return the current level of accuracy set on manager based upon currently set list of requests.
    /// It returns `nil` until you have the necessary permission from the user or GPS location is not currently in use.
    public var accuracy: Accuracy? {
        guard LocationManager.state == .available, queueLocationRequests.isEmpty == false else {
            return nil
        }
        return managerAccuracy
    }
    
    // MARK: - Background Updates -
    
    /// It is possible to force enable background location fetch even if your set any kind of Authorizations.
    public var backgroundLocationUpdates: Bool {
        set { self.manager.allowsBackgroundLocationUpdates = newValue }
        get { return self.manager.allowsBackgroundLocationUpdates }
    }
    
    /// Indicate whether the location manager object may pause location updates.
    /// See CLLocationManager's `pausesLocationUpdatesAutomatically` for a detailed explaination.
    public var pausesLocationUpdatesAutomatically: Bool {
        set { self.manager.pausesLocationUpdatesAutomatically = newValue }
        get { return self.manager.pausesLocationUpdatesAutomatically }
    }
    
    /// A Boolean indicating whether the status bar changes its appearance when location services are used in the background.
    /// This property affects only apps that received always authorization.
    /// When such an app moves to the background, the system uses this property to determine whether to
    /// change the status bar appearance to indicate that location services are in use.
    ///
    /// Displaying a modified status bar gives the user a quick way to return to your app. The default value of this property is false.
    /// For apps with when-in-use authorization, the system always changes the status bar appearance when the
    /// app uses location services in the background.
    @available(iOS 11, *)
    public var showsBackgroundLocationIndicator: Bool {
        set { self.manager.showsBackgroundLocationIndicator = newValue }
        get { return self.manager.showsBackgroundLocationIndicator }
    }
    
    // MARK: - Events -
    
    /// Event called when a new request is added or removed from a queue.
    public var onQueueChange = Observers<QueueChange>()
    public var onAuthorizationChange = Observers<AuthorizationChange>()

    /// Core Location may call this method in an effort to calibrate the onboard hardware
    /// used to determine heading values. Typically, Core Location calls this method at the following times:
    ///     - The first time heading updates are ever requested
    ///     - When Core Location observes a significant change in magnitude or inclination of the observed magnetic field
    ///
    /// If you return true from this method, Core Location displays the heading calibration alert
    /// on top of the current window immediately.
    /// The calibration alert prompts the user to move the device in a particular pattern so that Core Location
    /// can distinguish between the Earth’s magnetic field and any local magnetic fields.
    /// The alert remains visible until calibration is complete or until you explicitly dismiss it
    /// by calling the dismissHeadingCalibrationDisplay() method.
    /// In the latter case, you can use this method to set up a timer and dismiss the interface after
    /// a specified amount of time has elapsed.
    public var shouldDisplayHeadingCalibration: Bool = true
    
    // MARK: - Private Properties -
    
    /// This is the list of the requests currently in queue.
    /// List is thread safe in read/write.
    internal private(set) var queueLocationRequests: LocationRequestSet
    
    /// This is the list of all geocoder (reverse/not reverse) requests currently active.
    internal private(set) var queueGeocoderRequests: GeocoderRequestSet
    
    /// This is the list of all autocomplete requests currently active.
    internal private(set) var queueAutocompleteRequests: AutocompleteRequestSet
    
    /// Location by IP requests.
    internal private(set) var queueLocationByIPRequests: IPRequestSet
    
    /// Heading requests.
    internal private(set) var queueHeadingRequests: HeadingRequestSet
    
    /// `CLLocationManager` instance used to receive events from GPS.
    private let manager = CLLocationManager()
    
    /// Last received location.
    public var lastLocation: CLLocation?
    
    /// Accuracy set for manager.
    public var managerAccuracy: Accuracy? {
        set {
            manager.desiredAccuracy = newValue?.value ?? CLLocationAccuracyAccuracyAny
        }
        get {
            return Accuracy(rawValue: manager.desiredAccuracy)
        }
    }
    
    // MARK: - Initialization -
    
    internal override init() {
        queueLocationRequests = LocationRequestSet()
        queueGeocoderRequests = GeocoderRequestSet()
        queueAutocompleteRequests = AutocompleteRequestSet()
        queueLocationByIPRequests = IPRequestSet()
        queueHeadingRequests = HeadingRequestSet()
        super.init()
        manager.delegate = self
        
        // iOS 9 requires setting allowsBackgroundLocationUpdates to true in order to receive
        // background location updates.
        // We only set it to true if the location background mode is enabled for this app,
        // as the documentation suggests it is a fatal programmer error otherwise.
        if #available(iOSApplicationExtension 9.0, *) {
            if CLLocationManager.hasBackgroundCapabilities {
                manager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    // MARK: - Public Methods -
    
    /// Explicitly require authorization to the user in order to receive location events.
    /// You can call this method explicitly or you can leave it to be handled by the library.
    ///
    /// - Parameter mode: the default mode of the request, if nil `preferredAuthorization` mode is used.
    public func requireUserAuthorization(_ mode: CLLocationManager.AuthorizationMode? = nil) {
        manager.requestAuthorizationIfNeeded(mode ?? preferredAuthorization)
    }
    
    /// Create and enque a request to get the current device's location.
    ///
    /// - Parameters:
    ///   - subscription: type of subscription you want to set.
    ///   - accuracy: minimum accuracy to receive from GPS for this request.
    ///   - distance: The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
    ///   - activity: The location manager uses the information in this property as a cue to determine when location updates
    ///               may be automatically paused.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func locateFromGPS(_ subscription: LocationRequest.Subscription,
                              accuracy: Accuracy, distance: CLLocationDistance? = nil, activity: CLActivityType = .other,
                              timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                              result: LocationRequest.Callback?) -> LocationRequest {
        let request = LocationRequest()
        request.accuracy = accuracy
        request.distance = (distance ?? kCLDistanceFilterNone)
        request.activityType = activity
        // only one shot requests has timeout
        request.timeoutManager = (subscription == .oneShot ? (timeout != nil ? Timeout(mode: timeout!) : nil) : nil)
        request.subscription = subscription
        if let result = result {
            request.observers.add(result)
        }
        let _ = request.start()
        return request
    }
    
    /// Return device's approximate location by using one of the specified services.
    /// Some services may require subscription and return approximate locations without requiring explicit permission to the user.
    ///
    /// - Parameters:
    ///   - service: service to use.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func locateFromIP(service: LocationByIPRequest.Service,
                             timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                             result: LocationByIPRequest.Callback?) -> LocationByIPRequest {
        
        let request: LocationByIPRequest!
        switch service {
        case .ipAPI:
            request = IPAPIRequest()
            
        case .ipApiCo:
            request = IPAPICoRequest()
            
        }
        
        if let result = result {
            request.observers.add(result)
        }
        request.timeoutManager = (timeout != nil ? Timeout(mode: timeout!) : nil)
        startIPLocationRequest(request)
        return request
    }
    
    
    /// Asynchronously requests the current heading of the device using location services.
    /// The current heading (the most recent one acquired, regardless of accuracy level),
    /// or nil if no valid heading was acquired
    ///
    /// - Parameters:
    ///   - accuracy: minimum accuracy you want to receive. `nil` to receive all events
    ///   - minInterval: minimum interval between each request. `nil` to receive all events regardless the interval.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    public func headingSubscription(accuracy: HeadingRequest.AccuracyDegree?, minInterval: TimeInterval? = nil,
                                    result: HeadingRequest.Callback?) -> HeadingRequest {
        
        let request = HeadingRequest(accuracy: accuracy, minInterval: minInterval)
        
        if let result = result {
            request.observers.add(result)
        }
        startHeadingRequest(request)
        return request
    }
    
    /// Get the location from address string and return a `CLLocation` object.
    ///
    /// - Parameters:
    ///   - address: address string or place to search
    ///   - region: A geographical region to use as a hint when looking up the specified address.
    ///             Specifying a region lets you prioritize the returned set of results to locations
    ///             that are close to some specific geographical area, which is typically
    ///             the user’s current location. It's valid only if you are using apple services.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - service: service used to perform the operation. By default `apple` is used. Each service has its own configurable options.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func locateFromAddress(_ address: String, inRegion region: CLRegion? = nil,
                                  timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                                  service: GeocoderRequest.Service = .apple(nil),
                                  result: GeocoderRequest.Callback?) -> GeocoderRequest {
        
        let timeoutManager = (timeout != nil ? Timeout(mode: timeout!) : nil)
        var request: GeocoderRequest!
        
        switch service {
        case .apple(let options):
            request = AppleGeocoderRequest(address: address, region: region)
            request.options = options ?? GeocoderRequest.Options()
            
        case .google(let options):
            request = GoogleGeocoderRequest(address: address, region: region)
            request.options = options
            
        case .openStreet(let options):
            request = OpenStreetGeocoderRequest(address: address, region: region)
            request.options = options
            
        }
        
        request.timeoutManager = timeoutManager
        if let result = result {
            request.observers.add(result)
        }
        startGeocoder(request)
        return request
    }
    
    /// Reverse geocoding given coordinates and return a list of places found at specified location.
    ///
    /// - Parameters:
    ///   - coordinates: coordinates of the place to retrive info about.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - service: service used to perform the operation. By default `apple` is used.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func locateFromCoordinates(_ coordinates: CLLocationCoordinate2D,
                                      timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                                      service: GeocoderRequest.Service = .apple(nil),
                                      result: GeocoderRequest.Callback?) -> GeocoderRequest {
        
        let timeoutManager = (timeout != nil ? Timeout(mode: timeout!) : nil)
        var request: GeocoderRequest!
        
        switch service {
        case .apple(let options):
            request = AppleGeocoderRequest(coordinates: coordinates)
            request.options = options ?? GoogleGeocoderRequest.Options()
            
        case .google(let options):
            request = GoogleGeocoderRequest(coordinates: coordinates)
            request.options = options
            
        case .openStreet(let options):
            request = OpenStreetGeocoderRequest(coordinates: coordinates)
            request.options = options
            
        }
        
        request.timeoutManager = timeoutManager
        if let result = result {
            request.observers.add(result)
        }
        startGeocoder(request)
        return request
    }
    
    /// Autocomplete places from input string.
    ///
    /// - Parameters:
    ///   - partial: partial search string or search for place detail.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - service: service used to perform the operation. By default `apple` is used.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func autocomplete(partialMatch: AutoCompleteRequest.Operation,
                             timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                             service: AutoCompleteRequest.Service,
                             result: AutoCompleteRequest.Callback?) -> AutoCompleteRequest {
        
        let timeoutManager = (timeout != nil ? Timeout(mode: timeout!) : nil)
        
        var request: AutoCompleteRequest!
        
        switch service {
        case .apple(let options):
            request = AppleAutoCompleteRequest()
            request.options = options ?? AppleAutoCompleteRequest.Options()
            
        case .google(let options):
            request = GoogleAutoCompleteRequest()
            request.options = options
            
        }
        
        request.options?.operation = partialMatch
        request.timeoutManager = timeoutManager
        if let result = result {
            request.observers.add(result)
        }
        startAutoComplete(request)
        return request
    }
    
    // MARK: - Private Methods: Heading Request -
    
    internal func startHeadingRequest(_ request: HeadingRequest) {
        request.state = .idle
        let res = queueHeadingRequests.insert(request) // insert in queue
        if res.inserted {
            dispatchQueueChangeEvent(true, request: request)
        }
        self.updateHeadingSettings()
    }
    
    internal func removeHeadingRequest(_ request: HeadingRequest) {
        request.state = .expired
        if let _ = queueHeadingRequests.remove(request) {
            dispatchQueueChangeEvent(false, request: request)
        }
        self.updateHeadingSettings()
    }
    
    internal func updateHeadingSettings() {
        guard queueHeadingRequests.isEmpty == false else {
            manager.stopUpdatingHeading()
            return
        }
        manager.startUpdatingHeading()
    }
    
    // MARK: - Private Methods: IP Request -
    
    internal func startIPLocationRequest(_ request: LocationByIPRequest) {
        request.state = .idle
        let result = queueLocationByIPRequests.insert(request) // insert in queue
        if result.inserted {
            dispatchQueueChangeEvent(true, request: request)
        }
        let _ = request.start() // execute start
    }
    
    internal func removeIPLocationRequest(_ request: LocationByIPRequest) {
        request.state = .expired
        if let _ = queueLocationByIPRequests.remove(request) {
            dispatchQueueChangeEvent(false, request: request)
        }
    }
    
    // MARK: - Private Methods: Autocomplete -
    
    internal func startAutoComplete(_ request: AutoCompleteRequest) {
        request.state = .idle
        let result = queueAutocompleteRequests.insert(request) // insert in queue
        if result.inserted {
            dispatchQueueChangeEvent(true, request: request)
        }
        let _ = request.start() // execute start
    }
    
    internal func removeAutoComplete(_ request: AutoCompleteRequest) {
        request.state = .expired
        if let _ = queueAutocompleteRequests.remove(request) {
            dispatchQueueChangeEvent(false, request: request)
        }
    }
    
    // MARK: - Private Methods: Geocoder -
    
    internal func startGeocoder(_ request: GeocoderRequest) {
        request.state = .idle
        let result = queueGeocoderRequests.insert(request) // insert in queue
        if result.inserted {
            dispatchQueueChangeEvent(true, request: request)
        }
        let _ = request.start() // execute start
    }
    
    internal func removeGeocoder(_ request: GeocoderRequest) {
        request.state = .expired
        if let _ = queueGeocoderRequests.remove(request) {
            dispatchQueueChangeEvent(false, request: request)
        }
    }
    
    // MARK: - Private Methods: GPS Location -
    
    /// Remove location from the list of requests.
    ///
    /// - Parameter request: request to remove.
    internal func removeLocation(_ request: LocationRequest) {
        request.state = .expired
        if let _ = queueLocationRequests.remove(request) {
            dispatchQueueChangeEvent(false, request: request)
            updateLocationManagerSettings(request)
        }
    }
    
    /// Start a new request.
    ///
    /// - Parameter request: request to start.
    /// - Returns: `true` if added correctly to the queue, `false` otherwise.
    @discardableResult
    internal func startLocation(_ request: LocationRequest) -> Bool {
        guard request.state.isRunning == false else {
            return true
        }
        request.state = (LocationManager.state == .available ? .running : .idle) // change the state
        request.timeoutManager?.startIfNeeded()
        let result = queueLocationRequests.insert(request)
        if result.inserted {
            dispatchQueueChangeEvent(true, request: request)
        }
        
        updateLocationManagerSettings(request)
        return true
    }
    
    // MARK: - Evaluation of settings -
    
    public func evaluateRequiredAccuracy() -> Accuracy {
        let accuracy = queueLocationRequests.max(by: { (lhs, rhs) in
            return lhs.accuracy > rhs.accuracy
        })?.accuracy
        return accuracy ?? .any
    }
    
    public func evaluateRequiredDistanceFilter() -> CLLocationDistance {
        let minDistance = queueLocationRequests.min { (lhs, rhs) in
            return lhs.distance < rhs.distance
        }?.distance
        return minDistance ?? kCLDistanceFilterNone
    }
    
    public func evaluateActivityType() -> CLActivityType {
        let highestActivity = queueLocationRequests.max { (lhs, rhs) in
            return lhs.activityType.rawValue > rhs.activityType.rawValue
        }?.activityType
        return highestActivity ?? .other
    }
    
    /// Adjust the location manager settings based upon the currently running requests and new added request.
    ///
    /// - Parameter request: request added to queue.
    private func updateLocationManagerSettings(_ request: LocationRequest) {
        // adjust accuracy based on requests
        self.managerAccuracy = self.evaluateRequiredAccuracy()
        self.manager.distanceFilter = self.evaluateRequiredDistanceFilter()
        self.manager.activityType = self.evaluateActivityType()
        
        switch request.subscription {
        case .oneShot, .continous:
            // Request authorization only if needed
            manager.requestAuthorizationIfNeeded(preferredAuthorization)
            guard countRequestsInStates([.idle,.running]) > 0 || LocationManager.state != .available else {
                // if no running requests are active we can stop monitoring
                manager.stopUpdatingLocation()
                return
            }
            manager.startUpdatingLocation()
            
        case .significant:
            guard queueLocationRequests.filter( { $0.subscription == .significant }).isEmpty == false else {
                // if no significant location needs to be monitored we can stop monitoring it.
                manager.stopMonitoringSignificantLocationChanges()
                return
            }
            /// The significant-change location service requires always authorization.
            /// With this service, the location manager ignores the values in its distanceFilter and
            /// desiredAccuracy properties, so you do not need to configure them.
            requireUserAuthorization(.always)
            /// Start monitoring
            manager.startMonitoringSignificantLocationChanges()
            break
        }
        
    }
    
    internal func dispatchQueueChangeEvent(_ new: Bool, request: ServiceRequest) {
        onQueueChange.list.forEach {
            $0(new,request)
        }
    }
    
    /// Complete all requests in list and remove them. Optionally you can also pass a reason.
    ///
    /// - Parameter error: error used to complete each request. By default is `.cancelled`.
    public func completeAllLocationRequest(error: ErrorReason = .cancelled) {
        queueLocationRequests.forEach {
            $0.stop(reason: error, remove: true)
            updateLocationManagerSettings($0)
        }
    }
    
    /// Count the number of requests enqueued into the list of states.
    ///
    /// - Parameter states: states to filter.
    /// - Returns: `Int`
    private func countRequestsInStates(_ states: Set<RequestState>) -> Int {
        return queueLocationRequests.count(where: {
            states.contains($0.state)
        })
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    // MARK: - CLLocationManagerDelegate Heading -
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        queueHeadingRequests.forEach {
            $0.complete(heading: newHeading)
        }
    }
    
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return shouldDisplayHeadingCalibration
    }
    
    // MARK: - CLLocationManagerDelegate Location -
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange.callbacks.forEach { item in
            item.value(LocationManager.state)
        }
        
        guard status != .denied && status != .restricted else {
            // Clear out any active location requests (which will execute the blocks with a status that reflects
            // the unavailability of location services) since we now no longer have location services permissions
            completeAllLocationRequest(error: .invalidAuthStatus(status))
            return
        }
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            // we got the authorization, start any non paused request and any delayed timeout
            queueLocationRequests.forEach {
                $0.switchToRunningIfNotPaused()
                $0.timeoutManager?.startIfNeeded()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        lastLocation = mostRecentLocation
        for request in queueLocationRequests { // dispatch location to any request
            request.complete(location: mostRecentLocation)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        for request in queueLocationRequests { // dispatch the error to any request
            let shouldRemove = !(request.subscription == .oneShot) // oneshot location will be removed in this case
            request.stop(reason: .generic(error.localizedDescription), remove: shouldRemove)
        }
    }
    
}
