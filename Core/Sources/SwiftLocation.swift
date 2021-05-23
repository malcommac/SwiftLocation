//
//  SwiftLocation.swift
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation

#if os(OSX)
import AppKit
#else
import UIKit
#endif

/// Shortcut
public let SwiftLocation = LocationManager.shared

public class LocationManager: LocationManagerDelegate, CustomStringConvertible {
        
    // MARK: - Private Properties

    private var manager: LocationManagerImpProtocol?
    
    // MARK: - Public Properties
    
    /// Current settings of underlying core location.
    public private(set) var currentSettings = LocationManagerSettings()
    
    /// Called when a new set of geofences requests has been restored.
    public var onRestoreGeofences: (([GeofencingRequest]) -> Void)?
    
    /// Called when a new set of gps requests has been restored from relaunched app instance.
    public var onRestoreGPS: (([GPSLocationRequest]) -> Void)?
    
    /// Called when a new set of visits requests has been restored from relaunched app instance.
    public var onRestoreVisits: (([VisitsRequest]) -> Void)?

    /// Shared instance.
    public static let shared = LocationManager()
    
    /// Credentials storage.
    public let credentials = SharedCredentials
    
    /// Return the precise authorization.
    /// NOTE: This is only valid in iOS14, for lower iOS versions it always return `.fullAccuracy`.
    public var preciseAccuracy: GPSLocationOptions.Precise {
        manager?.authorizationPrecise ?? .fullAccuracy
    }
    
    /// When enabled all requests of geofences, gps and visits are saved automatically and can be restored
    /// by handling the relative `onRestore*` callbacks.
    /// By default is set to `true`.
    public var automaticRequestSave = true
    
    /// Indicate whether the app should receive location updates when suspended.
    /// NOTE: ensure that you’ve enabled the Background mode location from the capabilities in your Xcode project.
    public var allowsBackgroundLocationUpdates: Bool {
        set { manager?.allowsBackgroundLocationUpdates = newValue }
        get { manager?.allowsBackgroundLocationUpdates ?? false }
    }
    
    /// Indicate  whether the location manager object may pause location updates.
    public var pausesLocationUpdatesAutomatically: Bool {
        set { manager?.pausesLocationUpdatesAutomatically = newValue }
        get { manager?.pausesLocationUpdatesAutomatically ?? false }
    }
    
    /// Last know gps location.
    public var lastKnownGPSLocation: CLLocation? {
        get {
            guard let data = UserDefaults.standard.object(forKey: UserDefaultsKeys.LastKnownGPSLocation) as? Data else {
                return nil
            }
            
            let location = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLLocation
            return location
        }
        set {
            guard let location = newValue else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.LastKnownGPSLocation)
                return
            }
            
            let data = NSKeyedArchiver.archivedData(withRootObject: location)
            UserDefaults.standard.setValue(data, forKey: UserDefaultsKeys.LastKnownGPSLocation)
        }
    }
    
    /// Authorization mode. By default the best authorization to get is based upon the plist file.
    /// If plist contains always usage description the always mode is used, otherwise only whenInUse is preferred.
    public var preferredAuthorizationMode: AuthorizationMode = .plist
    
    /// Current authorization status.
    public var authorizationStatus: CLAuthorizationStatus {
        return manager?.authorizationStatus ?? .notDetermined
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
    
    /// Beacon requests.
    public lazy var beaconsRequests: RequestQueue<BeaconRequest> = {
        let queue = RequestQueue<BeaconRequest>()
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
    
    // MARK: - Create GPS Requests
    
    /// Create a request to get the location of the user one time only.
    ///
    /// - Parameters:
    ///   - accuracy: accuracy desidered, by default is `any`.
    ///   - timeout: timeout; by default is set to 7 seconds after we got the user's authorizations.
    public func gpsLocation(accuracy: GPSLocationOptions.Accuracy = .any,
                            timeout: GPSLocationOptions.Timeout = .delayed(7)) -> GPSLocationRequest {
        gpsLocationWith {
            $0.accuracy = accuracy
            $0.timeout = timeout
        }
    }

    /// Get the location with GPS module with given options.
    ///
    /// - Parameter optionsBuilder: options for search.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func gpsLocationWith(_ optionsBuilder: ((GPSLocationOptions) -> Void)) -> GPSLocationRequest {
        let options = GPSLocationOptions()
        optionsBuilder(options)
        return gpsLocationWith(options)
    }
    
    /// Get the location with GPS module with given options.
    ///
    /// - Parameter options: options to use.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func gpsLocationWith(_ options: GPSLocationOptions) -> GPSLocationRequest {
        gpsRequests.add(GPSLocationRequest(options))
    }
    
    // MARK: - Create IP Location Requests

    /// Get the current approximate location by asking to the passed service.
    /// - Parameter service: service to use.
    /// - Returns: `IPLocationRequest`
    @discardableResult
    public func ipLocationWith(_ service: IPServiceProtocol) -> IPLocationRequest {
        ipRequests.add(IPLocationRequest(service))
    }
    
    // MARK: - Create Geocode/Reverse Geocoder Requests

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
    
    // MARK: - Create Autocomplete Requests
    
    /// Prepare a new request for address autocomplete.
    ///
    /// - Parameter service: service to use.
    /// - Returns: AutocompleteRequest
    @discardableResult
    public func autocompleteWith(_ service: AutocompleteProtocol) -> AutocompleteRequest {
        autocompleteRequests.add(AutocompleteRequest(service))
    }
    
    // MARK: - Create Geofence Requests

    /// Create a new geofence request.
    ///
    /// - Parameter options: settings for geofence.
    /// - Returns: GeofenceRequest
    @discardableResult
    public func geofenceWith(_ options: GeofencingOptions) -> GeofencingRequest {
        geofenceRequests.add(GeofencingRequest(options: options))
    }
    
    // MARK: - Create Visits Requests
    
    /// Create a new visits request.
    ///
    /// - Parameter activityType: To help the system determine when to pause updates, you must also assign an appropriate value to the activityType property of your location manager.
    /// - Returns: VisitsRequest
    public func visits(activityType: CLActivityType) -> VisitsRequest {
        visitsRequest.add(VisitsRequest(activityType: activityType))
    }
    
    // MARK: - Create Beacon Requests
    
    /// Init the BeaconMonitor and listen to the given Beacon.
    /// - Parameter beacon: Beacon instance the BeaconMonitor is listening for and it will be used to create a concrete CLBeaconRegion.
    /// - Returns: BeaconRequest
    public func beacon(_ beacon: BeaconRequest.Beacon) -> BeaconRequest {
        beaconsRequests.add(BeaconRequest(beacon: beacon))
    }
    
    /// Init the request and listen only to the given Beacons.
    /// The UUID(s) for the regions will be extracted from the Beacon Array. When Beacons with different UUIDs are defined multiple regions will be created.
    /// - Parameter beacons: Beacon instances the BeaconMonitor is listening for
    /// - Returns: BeaconRequest
    public func beacons(_ beacons: [BeaconRequest.Beacon]) -> BeaconRequest {
        beaconsRequests.add(BeaconRequest(beacons: beacons))
    }
    
    /// Init the request and listen only to the given UUID.
    /// - Parameter UUID: NSUUID for the region the locationManager is listening to.
    /// - Returns: BeaconRequest
    public func beaconsWithUUID(_ UUID: UUID) -> BeaconRequest {
        beaconsRequests.add(BeaconRequest(UUID: UUID))
    }
    
    /// Init the request and listen to multiple UUIDs.
    /// - Parameter UUIDs: Array of UUIDs for the regions the locationManager should listen to.
    /// - Returns: BeaconRequest
    public func beaconsWithUUIDs(_ UUIDs: [UUID]) -> BeaconRequest {
        beaconsRequests.add(BeaconRequest(UUIDs: UUIDs))
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
            
        case let beacon as BeaconRequest:
            beaconsRequests.remove(beacon)
            
        default:
            LocationManager.Logger.log("Failed to remove request: '\(request)'")
        }
    }
    
    /// Manually request authorizations.
    /// NOTE: Use only if you need to request authorization in custom screen; authorization is called automatically
    /// based on active requests.
    ///
    /// - Parameters:
    ///   - mode: mode to request authorization; by default is `.plist` (look at `Info.plist` file to get the best auth required.
    ///   - completion: completion callback.
    public func requestAuthorization(_ mode: AuthorizationMode = .plist,
                                     completion: @escaping ((CLAuthorizationStatus) -> Void)) {
        manager?.requestAuthorization(mode, completion)
    }
    
    /// Cancel subscription token with given id from their associated request.
    /// - Parameter tokenID: token identifier.
    public func cancel(subscription identifier: Identifier) {
        gpsRequests.list.first(where: { $0.subscriptionWithID(identifier) != nil })?.cancel(subscription: identifier)
    }
    
    // MARK: - Setting up
    
    /// This functiction change the underlying manager which manage the hardware. By default the `CLLocationManager` based
    /// object is used (`DeviceLocationManager`); this function should not be called directly but it's used for unit test.
    /// - Parameter manager: manager to use.
    /// - Throws: throw an exception if something fail.
    public func setUnderlyingManager(_ manager: LocationManagerImpProtocol) throws {
        resetAll() // reset all queues
        
        self.manager = try DeviceLocationManager(locator: self)
        self.manager?.delegate = self
    }
    
    // MARK: - State Managements
    
    /// Save the current state of the requests. If you call resume.
    @discardableResult
    public func saveState() -> Bool {
        guard automaticRequestSave else { return true }
        
        do {
            let defaults = UserDefaults.standard
            defaults.setValue(try JSONEncoder().encode(geofenceRequests.list), forKey: UserDefaultsKeys.GeofenceRequests)
            defaults.setValue(try JSONEncoder().encode(gpsRequests.list), forKey: UserDefaultsKeys.GPSRequests)
            defaults.setValue(try JSONEncoder().encode(visitsRequest.list), forKey: UserDefaultsKeys.VisitsRequests)
            return true
        } catch {
            LocationManager.Logger.log("Failed to save the state of the requests: \(error.localizedDescription)")
            return false
        }
    }

    public func restoreState() {
        guard automaticRequestSave else { return }
        
        // GEOFENCES
        // Validate saved requests with the currently monitored regions of CLManager and restore if found.
        let restorableGeofences: [GeofencingRequest] = decodeSavedQueue(UserDefaultsKeys.GeofenceRequests).filter {
            manager?.monitoredRegions.map({ $0.identifier }).contains($0.uuid) ?? false
        }
        
        onRestoreGeofences?(geofenceRequests.add(restorableGeofences, silent: true))
        onRestoreGPS?(gpsRequests.add(decodeSavedQueue(UserDefaultsKeys.GPSRequests), silent: true))
        onRestoreVisits?(visitsRequest.add(decodeSavedQueue(UserDefaultsKeys.VisitsRequests), silent: true))

        saveState()
    }
    
    // MARK: - Private Functions
    
    private func decodeSavedQueue<T: Codable>(_ userDefaultsKey: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            LocationManager.Logger.log("Failed to restore saved queue for \(String(describing: T.self)): \(error.localizedDescription)")
            return []
        }
    }
        
    /// Alert settings of the core location manager underlying implementation.
    /// - Parameters:
    ///   - newSettings: new settings.
    ///   - completion: completion callback.
    private func updateCoreLocationSettings(_ newSettings: LocationManagerSettings, _ completion: @escaping (() -> Void)) {
        guard currentSettings != newSettings else {
            completion()
            return
        } // same settings, no needs to perform any change

        currentSettings = newSettings
        LocationManager.Logger.log("CLLocationManager: \(currentSettings)")
        manager?.updateSettings(currentSettings)
        
        if currentSettings.precise == .fullAccuracy {
            // Request one time permission to the user to get the precise location.
            manager?.checkAndRequestForAccuracyAuthorizationIfNeeded({ _ in
                completion()
            })
        } else {
            completion()
        }
    }
    
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
            updateCoreLocationSettings(updatedSettings) { [weak self] in
                self?.sendRequestsToImplementation()
            }
            return
        }
        
        failWeakAuthorizationRequests()
        
        /// If at least one geofencing request is in progress we want to ask for always authorization,
        /// otherwise we can use the preferred authorization mode specified.
        let hasRequestsWithAlwaysAuthRequired = (
            geofenceRequests.hasActiveRequests ||
            visitsRequest.hasActiveRequests ||
            beaconsRequests.hasActiveRequests
        )
        let authMode: AuthorizationMode = (hasRequestsWithAlwaysAuthRequired ? .always : preferredAuthorizationMode)
        manager?.requestAuthorization(authMode) { [weak self] auth in
            guard auth.isAuthorized else {
                return
            }
            
            self?.updateCoreLocationSettings(updatedSettings, {
                self?.sendRequestsToImplementation()
            })
        }
    }
    
    private func sendRequestsToImplementation() {
        updateGeofencing()
        updateBeaconMonitoring()
    }
    
    private func updateGeofencing() {
        manager?.geofenceRegions(Array(geofenceRequests.list))
    }
    
    private func updateBeaconMonitoring() {
        // Get the list of all regions to monitor.
        let allRegions = beaconsRequests.list.reduce(into: [CLBeaconRegion]()) { (list, req) in
            list.append(contentsOf: req.monitoredRegions)
        }
        
        manager?.monitorBeaconRegions(allRegions)
    }
    
    private func failWeakAuthorizationRequests() {
        guard authorizationStatus.isRejected == true else {
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
        
        // GPS
        enumerateQueue(gpsRequests) { request in
            services.insert(request.options.subscription.service)
            
            settings.precise = max(settings.precise, (request.options.precise ?? .reducedAccuracy))
            settings.accuracy = min(settings.accuracy, request.options.accuracy)
            settings.minDistance = max(settings.minDistance, request.options.minDistance)
            settings.activityType = CLActivityType(rawValue: max(settings.activityType.rawValue, request.options.activityType.rawValue)) ?? .other
        }
        
        // Geofence
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
        
        // Beacons
        if beaconsRequests.hasActiveRequests {
            services.insert(.beacon)
        }
        
        settings.activeServices = services
        
        return settings
    }
    
    // MARK: - Location Delegate Evenets
    
    public func locationManager(didFailWithError error: Error) {
        let error = LocationError.generic(error)
        
        dispatchDataToQueue(gpsRequests, data: .failure(error))
        dispatchDataToQueue(visitsRequest, data: .failure(error))
    }
    
    public func locationManager(didReceiveLocations locations: [CLLocation]) {
        guard let lastLocation = locations.max(by: CLLocation.mostRecentsTimeStampCompare) else {
            return
        }
        
        lastKnownGPSLocation = lastLocation
        dispatchDataToQueue(gpsRequests, data: .success(lastLocation))
    }
    
    public func locationManager(didVisits visit: CLVisit) {
        dispatchDataToQueue(visitsRequest, data: .success(visit))
    }
    
    // MARK: - Geofencing Delegate Events
    
    public func locationManager(geofenceEvent event: GeofenceEvent) {
        geofenceRequestForRegion(event.region)?.receiveData(.success(event))
    }
    
    public func locationManager(geofenceError error: LocationError, region: CLRegion?) {
        if let region = region { // specific error for a region
            geofenceRequestForRegion(region)?.receiveData(.failure(.generic(error)))
        } else { // generic error, will discard all monitored regions
            enumerateQueue(geofenceRequests) { request in
                request.receiveData(.failure(error))
            }
        }
    }
    
    // MARK: - Beacons Delegate Events

    public func locationManager(didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        enumerateQueue(beaconsRequests) { request in
            if let matchedBeacons = request.matchingBeacons(beacons, inRegion: region) {
                request.receiveData(.success(.rangingBeacons(matchedBeacons)))
            }
        }
    }
    
    public func locationManager(didEnterBeaconRegion region: CLBeaconRegion) {
        enumerateQueue(beaconsRequests) { request in
            if request.matchingRegion(region) {
                request.receiveData(.success(.didEnterRegion(region)))
            }
        }
    }
    
    public func locationManager(didExitBeaconRegion region: CLBeaconRegion) {
        enumerateQueue(beaconsRequests) { request in
            if request.matchingRegion(region) {
                request.receiveData(.success(.didExitRegion(region)))
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
                                                         data: Result<T.ProducedData, LocationError>) {
        let copyList = queue.list
        copyList.forEach { request in
            if filter?(request) ?? true {
                if let discardReason = request.receiveData(data) {
                    LocationManager.Logger.log("𝗑 Location discarded from \(request.uuid): \(discardReason.description)")
                }
            }
        }
    }
    
}

// MARK: - RequestQueue

public extension LocationManager {
    
    class RequestQueue<Value: RequestProtocol>: CustomStringConvertible {
        
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
            LocationManager.Logger.log("+ Add new request: \(request.uuid)")
            
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
            
            LocationManager.Logger.log("+ Add requests: \(requests.map({ $0.uuid }).joined(separator: ","))")
            
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
            LocationManager.Logger.log("- Remove request: \(request.uuid)")
            
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
            LocationManager.Logger.log("- Remove all \(list.count) requests")
            list.removeAll()
            
            removedRequests.forEach({ $0.didRemovedFromQueue() })
            
            if !silent {
                onUpdateSettings?()
            }
        }
        
    }
    
}

// MARK: - UserDefaultsKeys

fileprivate enum UserDefaultsKeys {
    static let GeofenceRequests = "com.swiftlocation.requests.geofence"
    static let GPSRequests = "com.swiftlocation.requests.gps"
    static let VisitsRequests = "com.swiftlocation.visits.gps"
    static let LastKnownGPSLocation = "com.swiftlocation.last-gps-location"
}
