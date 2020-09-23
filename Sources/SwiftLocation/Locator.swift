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

    private var manager: LocationManagerProtocol!
    
    // MARK: - Public Properties
    
    /// Shared instance.
    public static let shared = Locator()
    
    /// Queued location result.
    public private(set) var locationRequests = Set<LocationRequest>()
    
    /// Authorization mode. By default the best authorization to get is based upon the plist file.
    /// If plist contains always usage description the always mode is used, otherwise only whenInUse is preferred.
    public var preferredAuthorizationMode: AuthorizationMode = .plist
    
    /// Current authorization status.
    public var authorizationStatus: CLAuthorizationStatus {
        return manager.authorizationStatus
    }
    
    // MARK: - Initialization
    
    private init() {
        do {
            try setUnderlyingManager(DeviceLocationManager(locator: self))
        } catch {
            fatalError("Failed to setup Locator: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Properties
    
    /// This functiction change the underlying manager which manage the hardware. By default the `CLLocationManager` based
    /// object is used (`DeviceLocationManager`); this function should not be called directly but it's used for unit test.
    /// - Parameter manager: manager to use.
    /// - Throws: throw an exception if something fail.
    public func setUnderlyingManager(_ manager: LocationManagerProtocol) throws {
        resetAll() // reset all queues
        
        self.manager = try DeviceLocationManager(locator: self)
        self.manager.delegate = self
    }
    
    /// Get the location with given options.
    ///
    /// - Parameter optionsBuilder: options for search.
    /// - Returns: `LocationRequest`
    @discardableResult
    public func getLocation(_ optionsBuilder: ((inout LocationOptions) -> Void)) -> LocationRequest {
        let newRequest = LocationRequest()
        optionsBuilder(&newRequest.options)
        locationRequests.insert(newRequest)
        return newRequest
    }
    
    /// Cancel passed request from queue.
    ///
    /// - Parameter request: request.
    public func cancel(request: Any) {
        switch request {
        case let location as LocationRequest:
            locationRequests.remove(location)
            
        default:
            break
        }
    }
    
    /// Cancel subscription token with given id from their associated request.
    /// - Parameter tokenID: token identifier.
    public func cancel(subscription identifier: Identifier) {
        locationRequests.first(where: { $0.subscriptionWithID(identifier) != nil })?.cancel(subscription: identifier)
    }
    
    // MARK: - Private Functions
    
    /// Reset all location requests and manager's settings.
    private func resetAll() {
        locationRequests.removeAll()
        updateCoreLocationManagerSettings()
    }
    
    /// Update the settings of underlying core manager based upon the current settings.
    private func updateCoreLocationManagerSettings() {
        defer {
            startRequestsTimeoutsIfSet()
        }
        
        let bestSettings = bestSettingsForCoreLocationManager()
        
        guard bestSettings.requireLocationUpdates() else {
            manager.updateSettings(bestSettings)
            return
        }
        
        manager.requestAuthorization(preferredAuthorizationMode) { [weak self] auth in
            guard auth.isAuthorized else {
                return
            }
            self?.manager.updateSettings(bestSettings)
            return
        }
    }
    
    private func startRequestsTimeoutsIfSet() {
        enumerateLocationRequests { request in
            request.startTimeoutIfNeeded()
        }
    }
    
    private func bestSettingsForCoreLocationManager() -> LocationManagerSettings {
        var services = Set<LocationManagerSettings.Services>()
        var settings = LocationManagerSettings(activeServices: services)
        
        enumerateLocationRequests { request in
            services.insert(request.options.subscription.service)
            
            settings.accuracy = max(settings.accuracy, request.options.accuracy)
            settings.minDistance = min(settings.minDistance ?? -1, request.options.minDistance ?? -1)
            settings.activityType = CLActivityType(rawValue: max(settings.activityType.rawValue, request.options.activityType.rawValue)) ?? .other
        }
        
        if settings.minDistance == -1 { settings.minDistance = nil }
        
        return settings
    }
    
    // MARK: - LocationManagerDelegate
    
    public func locationManager(didFailWithError error: Error) {
        enumerateLocationRequests { request in
            request.receiveData(.failure(error))
        }
    }
    
    public func locationManager(didReceiveLocations locations: [CLLocation]) {
        dispatchLocationUpdate(locations)
    }
    
    // MARK: - Private Functions
    
    private func dispatchLocationUpdate(_ locations: [CLLocation]) {
        guard let lastLocation = locations.max(by: CLLocation.mostRecentsTimeStampCompare) else {
            return
        }
        
        enumerateLocationRequests { request in
            request.receiveData(.success(lastLocation))
        }
    }
    
    private func enumerateLocationRequests(_ callback: ((LocationRequest) -> Void)) {
        let requests = locationRequests
        requests.forEach(callback)
    }
    
}
