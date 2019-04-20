//
//  SwiftLocation.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 13/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation

/// LocationManager is the class used to manage each request.
public class LocationManager: NSObject {
    
    // MARK: - Public Typealiases -
    
    public typealias RequestID = String
    private typealias LocationRequestSet = Set<LocationRequest>
    private typealias GeocoderRequestSet = Set<GeocoderRequest>
    private typealias AutocompleteRequestSet = Set<AutoCompleteRequest>
    private typealias IPRequestSet = Set<LocationByIPRequest>
    private typealias HeadingRequestSet = Set<HeadingRequest>

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
    public var accuracy: Accuracy {
        return managerAccuracy
    }
    
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
    private var requestsQueue: Atomic<LocationRequestSet>
    
    /// This is the list of all geocoder (reverse/not reverse) requests currently active.
    private var geocoderRequestsQueue: Atomic<GeocoderRequestSet>
    
    /// This is the list of all autocomplete requests currently active.
    private var autocompleteRequestsQueue: Atomic<AutocompleteRequestSet>

    /// Location by IP requests.
    private var ipRequestsQueue: Atomic<IPRequestSet>

    /// Heading requests.
    private var headingRequestsQueue: Atomic<HeadingRequestSet>
    
    /// `CLLocationManager` instance used to receive events from GPS.
    private let manager = CLLocationManager()
    
    public var requiredAccuracy: Accuracy {
        return requestsQueue.atomic.max(by: { (lhs, rhs) in
            return lhs.accuracy > rhs.accuracy
        })?.accuracy ?? .any
    }
    
    /// Accuracy set for manager.
    public var managerAccuracy: Accuracy {
        set {
            manager.desiredAccuracy = managerAccuracy.value
        }
        get {
            return Accuracy(rawValue: manager.desiredAccuracy)
        }
    }
    
    // MARK: - Initialization -
    
    internal override init() {
        requestsQueue = Atomic(LocationRequestSet())
        geocoderRequestsQueue = Atomic(GeocoderRequestSet())
        autocompleteRequestsQueue = Atomic(AutocompleteRequestSet())
        ipRequestsQueue = Atomic(IPRequestSet())
        headingRequestsQueue = Atomic(HeadingRequestSet())
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
    
    /// Create and enque a request to get the current device's location.
    ///
    /// - Parameters:
    ///   - subscription: type of subscription you want to set.
    ///   - accuracy: minimum accuracy to receive from GPS for this request.
    ///   - timeout: if set a valid timeout interval to set; if you don't receive events in this interval requests will expire.
    ///   - result: callback where you will receive the result of request.
    /// - Returns: return the request itself you can use to manage the lifecycle.
    @discardableResult
    public func locateFromGPS(_ subscription: LocationRequest.Subscription,
                              accuracy: Accuracy, timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                              result: @escaping LocationRequest.Callback) -> LocationRequest {
        let request = LocationRequest()
        request.accuracy = accuracy
        request.timeoutManager = (timeout != nil ? Timeout(mode: timeout!) : nil)
        request.subscription = subscription
        request.callbacks.add(result)
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
                             result: @escaping LocationRequest.Callback) -> LocationByIPRequest {
        
        let request: LocationByIPRequest!
        switch service {
        case .ipAPI:
            request = IPAPIRequest()
            
        case .ipApiCo:
            request = IPAPICoRequest()

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
                                    result: @escaping HeadingRequest.Callback) -> HeadingRequest {
        
        let request = HeadingRequest(accuracy: accuracy, minInterval: minInterval)
        request.callbacks.add(result)
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
                                  result: @escaping GeocoderRequest.Callback) -> GeocoderRequest {

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
        request.callbacks.add(result)
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
                                      result: @escaping GeocoderRequest.Callback) -> GeocoderRequest {
        
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
        request.callbacks.add(result)
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
    public func autocomplete(partialMatch: AutoCompleteRequest.Operation,
                             timeout: Timeout.Mode? = .delayed(LocationManager.shared.timeout),
                             service: AutoCompleteRequest.Service,
                             result: @escaping AutoCompleteRequest.Callback) -> AutoCompleteRequest {
        
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
        request.callbacks.add(result)
        startAutoComplete(request)
        return request
    }
    
    // MARK: - Private Methods: Heading Request -

    internal func startHeadingRequest(_ request: HeadingRequest) {
        headingRequestsQueue.mutate {
            request.state = .idle
            $0.insert(request) // insert in queue
            self.updateHeadingSettings()
        }
    }
    
    internal func removeHeadingRequest(_ request: HeadingRequest) {
        headingRequestsQueue.mutate {
            request.state = .expired
            $0.remove(request)
            self.updateHeadingSettings()
        }
    }
    
    internal func updateHeadingSettings() {
        guard headingRequestsQueue.atomic.isEmpty == false else {
            manager.stopUpdatingHeading()
            return
        }
        manager.startUpdatingHeading()
    }
    
    // MARK: - Private Methods: IP Request -
    
    internal func startIPLocationRequest(_ request: LocationByIPRequest) {
        ipRequestsQueue.mutate {
            request.state = .idle
            $0.insert(request) // insert in queue
            let _ = request.start() // execute start
        }
    }
    
    internal func removeIPLocationRequest(_ request: LocationByIPRequest) {
        ipRequestsQueue.mutate {
            $0.remove(request)
        }
    }
    
    // MARK: - Private Methods: Autocomplete -

    internal func startAutoComplete(_ request: AutoCompleteRequest) {
        autocompleteRequestsQueue.mutate {
            request.state = .idle
            $0.insert(request) // insert in queue
            let _ = request.start() // execute start
        }
    }
    
    internal func removeAutoComplete(_ request: AutoCompleteRequest) {
        autocompleteRequestsQueue.mutate {
            $0.remove(request)
        }
    }
    
    // MARK: - Private Methods: Geocoder -
    
    internal func startGeocoder(_ request: GeocoderRequest) {
        geocoderRequestsQueue.mutate {
            request.state = .idle
            $0.insert(request) // insert in queue
            let _ = request.start() // execute start
        }
    }
    
    internal func removeGeocoder(_ request: GeocoderRequest) {
        geocoderRequestsQueue.mutate {
            $0.remove(request)
        }
    }
    
    // MARK: - Private Methods: GPS Location -
    
    /// Remove location from the list of requests.
    ///
    /// - Parameter request: request to remove.
    internal func removeLocation(_ request: LocationRequest) {
        requestsQueue.mutate {
            $0.remove(request)
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
        requestsQueue.mutate {
            request.state = .idle
            request.timeoutManager?.startIfNeeded()
            $0.insert(request)
        }
        
        updateLocationManagerSettings(request)
        return true
    }
    
    /// Adjust the location manager settings based upon the currently running requests and new added request.
    ///
    /// - Parameter request: request added to queue.
    private func updateLocationManagerSettings(_ request: LocationRequest) {
        // adjust accuracy based on requests
        self.managerAccuracy = self.requiredAccuracy

        switch request.subscription {
        case .oneShot, .continous:
            // Request authorization only if needed
            manager.requestAuthorizationIfNeeded(preferredAuthorization)
            guard countRequestsInStates([.idle,.running]) > 0 else {
                // if no running requests are active we can stop monitoring
                manager.stopUpdatingLocation()
                return
            }
            manager.startUpdatingLocation()
            
        case .significant:
            guard requestsQueue.atomic.filter( { $0.subscription == .significant }).isEmpty == false else {
                // if no significant location needs to be monitored we can stop monitoring it.
                manager.stopMonitoringSignificantLocationChanges()
                return
            }
            manager.startMonitoringSignificantLocationChanges()
            break
        }
        
    }
    
    /// Complete all requests in list and remove them.
    ///
    /// - Parameter error: error used to complete each request.
    private func completeAllLocationRequest(error: ErrorReason) {
        requestsQueue.atomic.forEach {
            $0.stop(reason: error, remove: true)
            updateLocationManagerSettings($0)
        }
    }
    
    /// Count the number of requests enqueued into the list of states.
    ///
    /// - Parameter states: states to filter.
    /// - Returns: `Int`
    private func countRequestsInStates(_ states: Set<RequestState>) -> Int {
        return requestsQueue.atomic.count(where: {
            states.contains($0.state)
        })
    }
    
}

extension LocationManager: CLLocationManagerDelegate {

    // MARK: - CLLocationManagerDelegate Heading -

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingRequestsQueue.atomic.forEach {
            $0.dispatch(data: .success(newHeading))
        }
    }
    
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return shouldDisplayHeadingCalibration
    }

    // MARK: - CLLocationManagerDelegate Location -
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .denied && status != .restricted else {
            // Clear out any active location requests (which will execute the blocks with a status that reflects
            // the unavailability of location services) since we now no longer have location services permissions
            completeAllLocationRequest(error: .invalidAuthStatus(status))
            return
        }
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            // we got the authorization, start any non paused request and any delayed timeout
            requestsQueue.atomic.forEach {
                $0.switchToRunningIfNotPaused()
                $0.timeoutManager?.startIfNeeded()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        for request in requestsQueue.atomic { // dispatch location to any request
            request.complete(location: mostRecentLocation)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        for request in requestsQueue.atomic { // dispatch the error to any request
            let shouldRemove = !(request.subscription == .oneShot) // oneshot location will be removed in this case
            request.stop(reason: .generic(error.localizedDescription), remove: shouldRemove)
        }
    }
    
}
