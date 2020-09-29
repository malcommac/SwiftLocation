//
//  Locator.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

public class Locator: LocationManagerDelegate {
        
    // MARK: - Private Properties

    private var manager: LocationManagerProtocol?
    
    // MARK: - Public Properties
    
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
            guard currentSettings != oldValue else {
                LocatorLogger.log("CLLocationManager: **settings ignored**")
                return
            } // same settings, no needs to perform any change

            LocatorLogger.log("CLLocationManager: \(currentSettings)")
            manager?.updateSettings(currentSettings)
        }
    }
    
    // MARK: - Queues
    
    /// Queued location result.
    private lazy var gpsRequests: RequestQueue<GPSLocationRequest> = {
        let queue = RequestQueue<GPSLocationRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.updateCoreLocationManagerSettings()
        }
        return queue
    }()
    
    private lazy var ipRequests: RequestQueue<IPLocationRequest> = {
        let queue = RequestQueue<IPLocationRequest>()
        queue.onUpdateSettings = { [weak self] in
            self?.updateCoreLocationManagerSettings()
        }
        return queue
    }()
    
    /// Geocoder requests
    private var geocoderRequests = RequestQueue<GeocoderRequest>()
    
    /// Address autocomplete requests
    private var autocompleteRequests = RequestQueue<AutocompleteRequest>()

    // MARK: - Initialization
    
    private init() {
        do {
            try setUnderlyingManager(DeviceLocationManager(locator: self))
        } catch {
            fatalError("Failed to setup Locator: \(error.localizedDescription)")
        }
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
    
    // MARK: - Public Properties
    
    /// Get the location with GPS module with given options.
    ///
    /// - Parameter optionsBuilder: options for search.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func getGPSLocation(_ optionsBuilder: ((GPSLocationOptions) -> Void)) -> GPSLocationRequest {
        let newRequest = GPSLocationRequest()
        optionsBuilder(newRequest.options)
        return gpsRequests.add(newRequest)
    }
    
    /// Get the location with GPS module with given options.
    ///
    /// - Parameter options: options to use.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func getGPSLocation(_ options: GPSLocationOptions) -> GPSLocationRequest {
        gpsRequests.add(GPSLocationRequest(options))
    }
    
    /// Get the current approximate location by asking to the passed service.
    /// - Parameter service: service to use.
    /// - Returns: `IPLocationRequest`
    @discardableResult
    public func getIPLocation(_ service: IPServiceProtocol) -> IPLocationRequest {
        ipRequests.add(IPLocationRequest(service))
    }
    
    /// Geocoding is the process of converting addresses (like "1600 Amphitheatre Parkway, Mountain View, CA") into geographic coordinates (like latitude 37.423021 and longitude -122.083739),
    /// which you can use to place markers on a map, or position the map.
    /// Reverse geocoding is the process of converting geographic coordinates into a human-readable address.
    /// This service allows you to perform both operations.
    ///
    /// - Parameter service: service to use.
    /// - Returns: GeocoderRequest
    public func getGeocode(_ service: GeocoderServiceProtocol) -> GeocoderRequest {
        geocoderRequests.add(GeocoderRequest(service: service))
    }
    
    /// Prepare a new request for address autocomplete.
    ///
    /// - Parameter service: service to use.
    /// - Returns: AutocompleteRequest
    public func getAutocomplete(_ service: AutocompleteProtocol) -> AutocompleteRequest {
        autocompleteRequests.add(AutocompleteRequest(service))
    }
    
    /// Cancel passed request from queue.
    ///
    /// - Parameter request: request.
    public func cancel(request: Any) {
        switch request {
        case let location as GPSLocationRequest:
            gpsRequests.remove(location)
            
        default:
            break
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
            return
        }
        
        failWeakAuthorizationRequests()
        
        manager?.requestAuthorization(preferredAuthorizationMode) { [weak self] auth in
            guard auth.isAuthorized else {
                return
            }
            self?.currentSettings = updatedSettings
            return
        }
    }
    
    private func failWeakAuthorizationRequests() {
        guard authorizationStatus.isAuthorized == false else {
            // If we have already the authorization even request with `avoidRequestAuthorization = true`
            // may receive notifications of locations.
            return
        }
        
        // If we have not authorization all requests with `avoidRequestAuthorization = true` should
        // fails with `authorizationNeeded` error.
        dispatchLocationDataToRequests(filter: {
            $0.options.avoidRequestAuthorization
        }, .failure(.authorizationNeeded))
    }
    
    private func startRequestsTimeoutsIfSet() {
        enumerateLocationRequests { request in
            request.startTimeoutIfNeeded()
        }
    }
    
    private func bestSettingsForCoreLocationManager() -> LocationManagerSettings {
        var services = Set<LocationManagerSettings.Services>()
        var settings = LocationManagerSettings(activeServices: services)
        
        print("\(gpsRequests.list.count) requests")
        enumerateLocationRequests { request in
            services.insert(request.options.subscription.service)
            
            settings.accuracy = min(settings.accuracy, request.options.accuracy)
            settings.minDistance = min(settings.minDistance ?? -1, request.options.minDistance ?? -1)
            settings.activityType = CLActivityType(rawValue: max(settings.activityType.rawValue, request.options.activityType.rawValue)) ?? .other
        }
        
        if settings.minDistance == -1 { settings.minDistance = nil }
        settings.activeServices = services
        
        return settings
    }
    
    // MARK: - LocationManagerDelegate
    
    public func locationManager(didFailWithError error: Error) {
        dispatchLocationDataToRequests(.failure(.generic(error)))
    }
    
    public func locationManager(didReceiveLocations locations: [CLLocation]) {
        dispatchLocationUpdate(locations)
    }
    
    // MARK: - Private Functions
    
    private func dispatchLocationUpdate(_ locations: [CLLocation]) {
        guard let lastLocation = locations.max(by: CLLocation.mostRecentsTimeStampCompare) else {
            return
        }
        
        dispatchLocationDataToRequests(.success(lastLocation))
    }
    
    private func enumerateLocationRequests(_ callback: ((GPSLocationRequest) -> Void)) {
        let requests = gpsRequests
        requests.list.forEach(callback)
    }
    
    private func dispatchLocationDataToRequests(filter: ((GPSLocationRequest) -> Bool)? = nil, _ data: Result<CLLocation, LocatorErrors>) {
        enumerateLocationRequests { request in
            if filter?(request) ?? true {
                if let discardReason = request.receiveData(data) {
                    LocatorLogger.log("𝗑 Location discarded from \(request.uuid): \(discardReason.description)")
                }
            }
        }
    }
    
}

public extension Locator {
    
    class RequestQueue<Value: RequestProtocol> {
        /// List of enqueued requests.
        public private(set) var list = Set<Value>()
        
        @discardableResult
        internal func add(_ request: Value) -> Value {
            LocatorLogger.log("+ Add new request: \(request.uuid)")
            
            list.insert(request)
            request.didAddInQueue()
            
            onUpdateSettings?()
            return request
        }

        @discardableResult
        internal func remove(_ request: Value) -> Value {
            LocatorLogger.log("- Remove request: \(request.uuid)")
            
            list.remove(request)
            request.didRemovedFromQueue()
            
            onUpdateSettings?()
            return request
        }
        
        internal func removeAll() {
            guard !list.isEmpty else { return }
            
            let removedRequests = list
            LocatorLogger.log("- Remove all \(list.count) requests")
            list.removeAll()
            
            removedRequests.forEach({ $0.didRemovedFromQueue() })
            
            onUpdateSettings?()
        }
        
        internal var onUpdateSettings: (() -> Void)?
    }
    
}
