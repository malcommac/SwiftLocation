//
//  Locator.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

#if os(OSX)
import AppKit
#else
import UIKit
#endif

public class Locator: LocationManagerDelegate, CustomStringConvertible {
        
    // MARK: - Private Properties

    private var manager: LocationManagerProtocol?
    
    // MARK: - Public Properties
    
    
    /// Called when a new set of geofences requests has been restored.
    public var onRestoreGeofences: (([GeofencingRequest]) -> Void)?
    
    /// Called when a new set of gps requests has been restored.
    public var onRestoreGPS: (([GPSLocationRequest]) -> Void)?
    
    /// Called when a new set of ip requests has been restored.
    public var onRestoreIP: (([IPLocationRequest]) -> Void)?
    
    /// Called when a new set of visits requests has been restored.
    public var onRestoreVisits: (([VisitsRequest]) -> Void)?
    
    /// Called when a new set of autocomplete requests has been restored.
    public var onRestoreAutocomplete: (([AutocompleteRequest]) -> Void)?
    
    /// Called when a new set of geocoder requests has been restored.
    public var onRestoreGeocode: (([GeocoderRequest]) -> Void)?
    
    /// Shared instance.
    public static let shared = Locator()
    
    /// Authorization mode. By default the best authorization to get is based upon the plist file.
    /// If plist contains always usage description the always mode is used, otherwise only whenInUse is preferred.
    public var preferredAuthorizationMode: AuthorizationMode = .plist
    
    /// Current authorization status.
    public var authorizationStatus: CLAuthorizationStatus {
        return manager?.authorizationStatus ?? .notDetermined
    }
    
    /// Currently active location settings
    public private(set) var currentSettings = LocationManagerSettings() {
        didSet {
            guard currentSettings != oldValue else { return } // same settings, no needs to perform any change

            LocatorLogger.log("CLLocationManager: \(currentSettings)")
            manager?.updateSettings(currentSettings)
        }
    }
    
    // MARK: - Requests Queues
    
    /// Location requests.
    public lazy var gpsRequests: RequestQueue<GPSLocationRequest> = {
        let queue = RequestQueue<GPSLocationRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.updateCoreLocationManagerSettings()
            self?.saveState()
        }
        return queue
    }()
    
    /// Geofencing requests.
    public lazy var geofenceRequests: RequestQueue<GeofencingRequest> = {
        let queue = RequestQueue<GeofencingRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.updateCoreLocationManagerSettings()
            self?.saveState()
        }
        return queue
    }()
    
    /// Visits requests
    public lazy var visitsRequest: RequestQueue<VisitsRequest> = {
        let queue = RequestQueue<VisitsRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.updateCoreLocationManagerSettings()
        }
        return queue
    }()
    
    /// IP Requests
    public lazy var ipRequests: RequestQueue<IPLocationRequest> = {
        let queue = RequestQueue<IPLocationRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.saveState()
        }
        return queue
    }()
    
    /// Geocoder Requests
    public lazy var geocoderRequests: RequestQueue<GeocoderRequest> = {
        let queue = RequestQueue<GeocoderRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.saveState()
        }
        return queue
    }()
    
    /// Autocomplete Requests.
    public lazy var autocompleteRequests: RequestQueue<AutocompleteRequest> = {
        let queue = RequestQueue<AutocompleteRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.saveState()
        }
        return queue
    }()

    public var description: String {
        let data: [String: Any] = [
            "settings": currentSettings.description,
            "autocomplete": autocompleteRequests.description,
            "ip": ipRequests.description,
            "visits": visitsRequest.description,
            "geofence": geofenceRequests.description,
            "gps": gpsRequests.description,
        ]
        return JSONStringify(data)
    }
    
    // MARK: - Initialization
    
    private init() {
        do {
            try setUnderlyingManager(DeviceLocationManager(locator: self))
        } catch {
            fatalError("Failed to setup Locator: \(error.localizedDescription)")
        }
    }
    
    deinit {
        saveState()
    }
    
    // MARK: - Setting up
    
    /// This functiction change the underlying manager which manage the hardware. By default the `CLLocationManager` based
    /// object is used (`DeviceLocationManager`); this function should not be called directly but it's used for unit test.
    /// - Parameter manager: manager to use.
    /// - Throws: throw an exception if something fail.
    public func setUnderlyingManager(_ manager: LocationManagerProtocol) throws {
        resetAll() // reset all queues
        
        self.manager = try DeviceLocationManager(locator: self)
        self.manager?.delegate = self
    }
    
    // MARK: - State Managements
    
    /// Save the current state of the requests. If you call resume.
    @discardableResult
    public func saveState() -> Bool {
        do {
            let defaults = UserDefaults.standard
            defaults.setValue(try JSONEncoder().encode(geofenceRequests.list), forKey: UserDefaultsKeys.GeofenceRequests)
            defaults.setValue(try JSONEncoder().encode(gpsRequests.list), forKey: UserDefaultsKeys.GPSRequests)
            defaults.setValue(try JSONEncoder().encode(ipRequests.list), forKey: UserDefaultsKeys.IPRequests)
            defaults.setValue(try JSONEncoder().encode(autocompleteRequests.list), forKey: UserDefaultsKeys.AutocompleteRequests)
            defaults.setValue(try JSONEncoder().encode(geocoderRequests.list), forKey: UserDefaultsKeys.GeocoderRequests)
            defaults.setValue(try JSONEncoder().encode(visitsRequest.list), forKey: UserDefaultsKeys.VisitsRequests)

            return true
        } catch {
            LocatorLogger.log("Failed to save the state of the requests: \(error.localizedDescription)")
            return false
        }
    }

    public func restoreState() {
        // GEOFENCES
        // Validate saved requests with the currently monitored regions of CLManager and restore if found.
        let restorableGeofences: [GeofencingRequest] = decodeSavedQueue(UserDefaultsKeys.GeofenceRequests).filter {
            manager?.monitoredRegions.map({ $0.identifier }).contains($0.uuid) ?? false
        }
        onRestoreGeofences?(geofenceRequests.add(restorableGeofences, silent: true))
        
        // SIGNIFICANT LOCATIONS
        
        // VISITS
       
        // Others (not to be evaluated)
        onRestoreGPS?(gpsRequests.add(decodeSavedQueue(UserDefaultsKeys.GPSRequests), silent: true))
        onRestoreVisits?(visitsRequest.add(decodeSavedQueue(UserDefaultsKeys.VisitsRequests), silent: true))
        onRestoreIP?(ipRequests.add(decodeSavedQueue(UserDefaultsKeys.IPRequests), silent: true))
        onRestoreAutocomplete?(autocompleteRequests.add(decodeSavedQueue(UserDefaultsKeys.AutocompleteRequests), silent: true))
        onRestoreGeocode?(geocoderRequests.add(decodeSavedQueue(UserDefaultsKeys.GeocoderRequests), silent: true))
        
        saveState()
    }
    
    private func decodeSavedQueue<T: Codable>(_ userDefaultsKey: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            LocatorLogger.log("Failed to restore saved queue for \(String(describing: T.self)): \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Public Properties
    
    /// Get the location with GPS module with given options.
    ///
    /// - Parameter optionsBuilder: options for search.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func gpsLocationWith(_ optionsBuilder: ((GPSLocationOptions) -> Void)) -> GPSLocationRequest {
        let newRequest = GPSLocationRequest()
        optionsBuilder(newRequest.options)
        return gpsRequests.add(newRequest)
    }
    
    /// Get the location with GPS module with given options.
    ///
    /// - Parameter options: options to use.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func gpsLocationWith(_ options: GPSLocationOptions) -> GPSLocationRequest {
        gpsRequests.add(GPSLocationRequest(options))
    }
    
    /// Get the current approximate location by asking to the passed service.
    /// - Parameter service: service to use.
    /// - Returns: `IPLocationRequest`
    @discardableResult
    public func ipLocationWith(_ service: IPServiceProtocol) -> IPLocationRequest {
        ipRequests.add(IPLocationRequest(service))
    }
    
    /// Geocoding is the process of converting addresses (like "1600 Amphitheatre Parkway, Mountain View, CA") into geographic coordinates (like latitude 37.423021 and longitude -122.083739),
    /// which you can use to place markers on a map, or position the map.
    /// Reverse geocoding is the process of converting geographic coordinates into a human-readable address.
    /// This service allows you to perform both operations.
    ///
    /// - Parameter service: service to use.
    /// - Returns: GeocoderRequest
    @discardableResult
    public func geocodeWith(_ service: GeocoderServiceProtocol) -> GeocoderRequest {
        geocoderRequests.add(GeocoderRequest(service: service))
    }
    
    /// Prepare a new request for address autocomplete.
    ///
    /// - Parameter service: service to use.
    /// - Returns: AutocompleteRequest
    @discardableResult
    public func autocompleteWith(_ service: AutocompleteProtocol) -> AutocompleteRequest {
        autocompleteRequests.add(AutocompleteRequest(service))
    }
    
    /// Create a new geofence request.
    ///
    /// - Parameter options: settings for geofence.
    /// - Returns: GeofenceRequest
    @discardableResult
    public func geofenceWith(_ options: GeofencingOptions) -> GeofencingRequest {
        geofenceRequests.add(GeofencingRequest(options: options))
    }
    
    /// Create a new visits request.
    ///
    /// - Parameter activityType: To help the system determine when to pause updates, you must also assign an appropriate value to the activityType property of your location manager.
    /// - Returns: VisitsRequest
    public func visits(activityType: CLActivityType) -> VisitsRequest {
        visitsRequest.add(VisitsRequest(activityType: activityType))
    }
    
    /// Cancel passed request from queue.
    ///
    /// - Parameter request: request.
    public func cancel(request: Any) {
        switch request {
        case let location as GPSLocationRequest:
            gpsRequests.remove(location)
            
        case let geofence as GeofencingRequest:
            geofenceRequests.remove(geofence)
            
        case let autocomplete as AutocompleteRequest:
            autocompleteRequests.remove(autocomplete)
            
        case let ipLocation as IPLocationRequest:
            ipRequests.remove(ipLocation)
            
        case let geocode as GeocoderRequest:
            geocoderRequests.remove(geocode)
            
        case let visits as VisitsRequest:
            visitsRequest.remove(visits)
            
        default:
            LocatorLogger.log("Failed to remove request: '\(request)'")
        }
    }
    
    /// Cancel subscription token with given id from their associated request.
    /// - Parameter tokenID: token identifier.
    public func cancel(subscription identifier: Identifier) {
        gpsRequests.list.first(where: { $0.subscriptionWithID(identifier) != nil })?.cancel(subscription: identifier)
    }
    
    // MARK: - Private Functions
    
    /// Reset all location requests and manager's settings.
    private func resetAll() {
        gpsRequests.removeAll()
        updateCoreLocationManagerSettings()
    }
    
    /// Update the settings of underlying core manager based upon the current settings.
    private func updateCoreLocationManagerSettings() {
        defer {
            startRequestsTimeoutsIfSet()
        }
        
        let updatedSettings = bestSettingsForCoreLocationManager()
        guard updatedSettings.requireLocationUpdates() else {
            self.currentSettings = updatedSettings
            self.updateGeofencing()
            return
        }
        
        failWeakAuthorizationRequests()
        
        /// If at least one geofencing request is in progress we want to ask for always authorization,
        /// otherwise we can use the preferred authorization mode specified.
        let authMode: AuthorizationMode = (geofenceRequests.hasActiveRequests || visitsRequest.hasActiveRequests ? .always : preferredAuthorizationMode)
        manager?.requestAuthorization(authMode) { [weak self] auth in
            guard auth.isAuthorized else {
                return
            }
            self?.currentSettings = updatedSettings
            self?.updateGeofencing()
            return
        }
    }
    
    private func updateGeofencing() {
        manager?.geofenceRegions(Array(geofenceRequests.list))
    }
    
    private func failWeakAuthorizationRequests() {
        guard authorizationStatus.isAuthorized == false else {
            // If we have already the authorization even request with `avoidRequestAuthorization = true`
            // may receive notifications of locations.
            return
        }
        
        // If we have not authorization all requests with `avoidRequestAuthorization = true` should
        // fails with `authorizationNeeded` error.
        dispatchDataToQueue(gpsRequests, filter: { request in
            request.options.avoidRequestAuthorization
        }, data: .failure(.authorizationNeeded))
    }
    
    private func startRequestsTimeoutsIfSet() {
        enumerateQueue(gpsRequests) { request in
            request.startTimeoutIfNeeded()
        }
    }
    
    private func bestSettingsForCoreLocationManager() -> LocationManagerSettings {
        // Setup settings for CoreLocationManager
        var services = Set<LocationManagerSettings.Services>()
        var settings = LocationManagerSettings(activeServices: services)
        
        enumerateQueue(gpsRequests) { request in
            services.insert(request.options.subscription.service)
            
            settings.accuracy = min(settings.accuracy, request.options.accuracy)
            settings.minDistance = min(settings.minDistance ?? -1, request.options.minDistance ?? -1)
            settings.activityType = CLActivityType(rawValue: max(settings.activityType.rawValue, request.options.activityType.rawValue)) ?? .other
        }
        
        // Geofence requests
        enumerateQueue(geofenceRequests) { request in
            if let circularRegion = request.monitoredRegion as? CLCircularRegion {
                settings.accuracy = min(settings.accuracy, GPSLocationOptions.Accuracy(rawValue: circularRegion.radius))
            }
        }
        
        // Visits
        if visitsRequest.hasActiveRequests {
            services.insert(.visits)
            enumerateQueue(visitsRequest) { request in
                settings.activityType = CLActivityType(rawValue: max(settings.activityType.rawValue, request.activityType.rawValue)) ?? .other
            }
        }
        
        if settings.minDistance == -1 { settings.minDistance = nil }
        settings.activeServices = services
        
        return settings
    }
    
    // MARK: - Location Delegate Evenets
    
    public func locationManager(didFailWithError error: Error) {
        let error = LocatorErrors.generic(error)
        
        dispatchDataToQueue(gpsRequests, data: .failure(error))
        dispatchDataToQueue(visitsRequest, data: .failure(error))
    }
    
    public func locationManager(didReceiveLocations locations: [CLLocation]) {
        guard let lastLocation = locations.max(by: CLLocation.mostRecentsTimeStampCompare) else {
            return
        }
        
        dispatchDataToQueue(gpsRequests, data: .success(lastLocation))
    }
    
    public func locationManager(didVisits visit: CLVisit) {
        dispatchDataToQueue(visitsRequest, data: .success(visit))
    }
    
    // MARK: - Geofencing Delegate Events
    
    public func locationManager(geofenceEvent event: GeofenceEvent) {
        geofenceRequestForRegion(event.region)?.receiveData(.success(event))
    }
    
    public func locationManager(geofenceError error: LocatorErrors, region: CLRegion?) {
        if let region = region { // specific error for a region
            geofenceRequestForRegion(region)?.receiveData(.failure(.generic(error)))
        } else { // generic error, will discard all monitored regions
            enumerateQueue(geofenceRequests) { request in
                request.receiveData(.failure(error))
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func geofenceRequestForRegion(_ region: CLRegion) -> GeofencingRequest? {
        return geofenceRequests.list.first(where: { $0.uuid == region.identifier })
    }
    
    private func enumerateQueue<T>(_ queue: RequestQueue<T>, _ callback: ((T) -> Void)) {
        let copyList = queue.list
        copyList.forEach(callback)
    }
    
    private func dispatchDataToQueue<T: RequestProtocol>(_ queue: RequestQueue<T>,
                                                         filter: ((T) -> Bool)? = nil,
                                                         data: Result<T.ProducedData, LocatorErrors>) {
        let copyList = queue.list
        copyList.forEach { request in
            if filter?(request) ?? true {
                if let discardReason = request.receiveData(data) {
                    LocatorLogger.log("𝗑 Location discarded from \(request.uuid): \(discardReason.description)")
                }
            }
        }
    }
    
}

// MARK: - RequestQueue

public extension Locator {
    
    class RequestQueue<Value: RequestProtocol & Codable>: Codable, CustomStringConvertible {
        
        // MARK: - Public Properties
        
        /// List of enqueued requests.
        public private(set) var list = Set<Value>()
        
        /// Return `true` if there is at least one active request.
        public var hasActiveRequests: Bool {
            return list.first { request in
                request.isEnabled
            } != nil
        }
        
        public var description: String {
            "\(list.count)"
        }
        
        // MARK: - Internal Properties
        
        /// Event called when one or more requests are added/removed from the queue.
        internal var onUpdateSettings: (() -> Void)?

        // MARK: - Internal Functions

        /// Add a new request to the queue.
        /// - Parameter request: request.
        /// - Returns: Self
        @discardableResult
        internal func add(_ request: Value, silent: Bool = false) -> Value {
            LocatorLogger.log("+ Add new request: \(request.uuid)")
            
            list.insert(request)
            request.didAddInQueue()
            
            if !silent {
                onUpdateSettings?()
            }
            
            return request
        }
        
        // MARK: - Initialization
        
        public init() {
            
        }
        
        // MARK: - Public Methods
        
        /// Append a list of requests into the list.
        ///
        /// - Parameter requests: requests to add.
        @discardableResult
        internal func add(_ requests: [Value], silent: Bool = false) -> [Value] {
            guard requests.isEmpty == false else { return [] }
            
            LocatorLogger.log("+ Add requests: \(requests.map({ $0.uuid }).joined(separator: ","))")
            
            requests.forEach {
                list.insert($0)
                $0.didAddInQueue()
            }
            
            if !silent {
                onUpdateSettings?()
            }
            return requests
        }
        
        /// Remove existing request from the queue.
        /// - Parameter request: request.
        /// - Returns: Self
        @discardableResult
        internal func remove(_ request: Value, silent: Bool = false) -> Value {
            LocatorLogger.log("- Remove request: \(request.uuid)")
            
            list.remove(request)
            request.didRemovedFromQueue()
            
            if !silent {
                onUpdateSettings?()
            }
            return request
        }
        
        /// Remove all requests from the queue.
        internal func removeAll(silent: Bool = false) {
            guard !list.isEmpty else { return }
            
            let removedRequests = list
            LocatorLogger.log("- Remove all \(list.count) requests")
            list.removeAll()
            
            removedRequests.forEach({ $0.didRemovedFromQueue() })
            
            if !silent {
                onUpdateSettings?()
            }
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case list
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(list, forKey: .list)
        }
        
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.list = try container.decode(Set<Value>.self, forKey: .list)
        }
        
    }
    
}

// MARK: - UserDefaultsKeys

fileprivate enum UserDefaultsKeys {
    static let GeofenceRequests = "com.swiftlocation.requests.geofence"
    static let GPSRequests = "com.swiftlocation.requests.gps"
    static let VisitsRequests = "com.swiftlocation.visits.gps"
    static let IPRequests = "com.swiftlocation.requests.ip"
    static let AutocompleteRequests = "com.swiftlocation.requests.autocomplete"
    static let GeocoderRequests = "com.swiftlocation.requests.geocoder"
}
