//
//  CLLocationManagerAware.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

// MARK: - LocationManagerDelegate

public protocol LocationManagerDelegate: class {
    
    // MARK: - Location Manager
    
    func locationManager(didFailWithError error: Error)
    func locationManager(didReceiveLocations locations: [CLLocation])
    
    // MARK: - Geofencing
    
    func locationManager(geofenceEvent event: GeofenceEvent)
    func locationManager(geofenceError error: LocatorErrors, region: CLRegion?)
    
    // MARK: - Visits
    
    func locationManager(didVisits visit: CLVisit)
}

// MARK: - LocationManagerProtocol

public protocol LocationManagerProtocol: class {
    typealias AuthorizationCallback = ((CLAuthorizationStatus) -> Void)

    var authorizationStatus: CLAuthorizationStatus { get }
    var delegate: LocationManagerDelegate? { get set }
    
    /// Initialize with a new locator.
    /// - Parameter locator: locator.
    init(locator: Locator) throws
    
    /// Request authorization.
    /// - Parameters:
    ///   - mode: mode.
    ///   - callback: callback.
    func requestAuthorization(_ mode: AuthorizationMode, _ callback: @escaping AuthorizationCallback)
    
    /// Update settings of the hardware based on running requests.
    /// - Parameter newSettings: settings.
    func updateSettings(_ newSettings: LocationManagerSettings)
    
    /// Activate geofence per requests.
    /// - Parameter requests: requests.
    func geofenceRegions(_ requests: [GeofencingRequest])
    
    /// Currently monitored regions
    var monitoredRegions: Set<CLRegion> { get }
    
}

// MARK: - DataDiscardReason

/// Reason to discard given data.
/// - `notMinAccuracy`: accuracy level not meet.
/// - `notMinDistance`: minimum distance not meet.
/// - `notMinInterval`: minimum interval not meet.
/// - `requestNotEnabled`: request is not enabled.
/// - `generic`: generic error.
public enum DataDiscardReason: CustomStringConvertible {
    case notMinAccuracy
    case notMinDistance
    case notMinInterval
    case requestNotEnabled
    case internalEvaluation
    case generic(Error)
    
    public var description: String {
        switch self {
        case .notMinAccuracy:       return "Not minimum accuracy"
        case .notMinDistance:       return "Not min distance"
        case .notMinInterval:       return "Not min interval"
        case .requestNotEnabled:    return "Request disabled"
        case .internalEvaluation:   return "Internal evaluation"
        case .generic(let e):       return e.localizedDescription
        }
    }
    
}

// MARK: - AuthorizationMode

/// Authorization request mod.
/// - `plist`: authorization level via plist data.
/// - `always`: authorization is always.
/// - `onlyInUse`: authorization only in use.
public enum AuthorizationMode: String, CustomStringConvertible {
    case plist
    case always
    case onlyInUse
    
    public var description: String {
        rawValue
    }
}

// MARK: - LocationManagerSettings

public struct LocationManagerSettings: CustomStringConvertible, Equatable {
    
    /// Services
    public enum Services: String, CustomStringConvertible {
        case continousLocation
        case significantLocation
        case visits

        public var description: String {
            rawValue
        }
    }
    
    // MARK: - Public Properties
    
    /// Active CoreLocation services to activate.
    var activeServices = Set<Services>()
    
    /// Accuracy needed.
    var accuracy: GPSLocationOptions.Accuracy = .any
    
    /// Minimum distance.
    var minDistance: CLLocationDistance?
    
    /// Activity type.
    var activityType: CLActivityType = .other
    
    public func requireLocationUpdates() -> Bool {
        return activeServices.contains(.continousLocation) ||
                activeServices.contains(.significantLocation) ||
            activeServices.contains(.visits)
    }
    
    public var description: String {
        let data: [String: Any] = [
            "services": activeServices.description,
            "accuracy": accuracy.description,
            "minDistance": minDistance ?? -1,
            "activityType": activityType.description
        ]
        return JSONStringify(data)
    }
    
}
