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
    func locationManager(didFailWithError error: Error)
    func locationManager(didReceiveLocations locations: [CLLocation])
}

// MARK: - LocationManagerProtocol

public protocol LocationManagerProtocol: class {
    typealias AuthorizationCallback = ((CLAuthorizationStatus) -> Void)

    var authorizationStatus: CLAuthorizationStatus { get }
    var delegate: LocationManagerDelegate? { get set }

    init(locator: Locator) throws

    func requestAuthorization(_ mode: AuthorizationMode, _ callback: @escaping AuthorizationCallback)
    
    func updateSettings(_ newSettings: LocationManagerSettings)
    
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
    case generic(Error)
    
    public var description: String {
        switch self {
        case .notMinAccuracy:   return "Not minimum accuracy"
        case .notMinDistance:   return "Not min distance"
        case .notMinInterval:   return "Not min interval"
        case .requestNotEnabled:return "Request disabled"
        case .generic(let e):   return e.localizedDescription
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
                activeServices.contains(.significantLocation)
    }
    
    public var description: String {
        return "\n{ \n\tservices = \(activeServices), \n\taccuracy = \(accuracy), \n\tminDistance = \(minDistance ?? -1), \n\tactivityType = \(activityType)\n}"
    }
    
}
