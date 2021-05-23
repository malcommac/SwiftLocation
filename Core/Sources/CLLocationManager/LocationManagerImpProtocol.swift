//
//  LocationManagerImpProtocol.swift
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

// MARK: - LocationManagerDelegate

public protocol LocationManagerDelegate: class {
    
    // MARK: - Location Manager
    func locationManager(didFailWithError error: Error)
    func locationManager(didReceiveLocations locations: [CLLocation])
    
    // MARK: - Geofencing
    func locationManager(geofenceEvent event: GeofenceEvent)
    func locationManager(geofenceError error: LocationError, region: CLRegion?)
    
    // MARK: - Visits
    func locationManager(didVisits visit: CLVisit)
    
    // MARK: - Beacons
    func locationManager(didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
    func locationManager(didEnterBeaconRegion region: CLBeaconRegion)
    func locationManager(didExitBeaconRegion region: CLBeaconRegion)

}

// MARK: - LocationManagerProtocol

public protocol LocationManagerImpProtocol: class {
    typealias AuthorizationCallback = ((CLAuthorizationStatus) -> Void)

    // Authorizations
    
    var authorizationStatus: CLAuthorizationStatus { get }
    var authorizationPrecise: GPSLocationOptions.Precise { get }
    
    // Delegate
    
    var delegate: LocationManagerDelegate? { get set }
    
    // Options
    
    var allowsBackgroundLocationUpdates: Bool { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }

    /// Initialize with a new locator.
    /// - Parameter locator: locator.
    init(locator: LocationManager) throws
    
    /// Request authorization.
    /// - Parameters:
    ///   - mode: mode.
    ///   - callback: callback.
    func requestAuthorization(_ mode: AuthorizationMode?, _ callback: @escaping AuthorizationCallback)
    
    /// Check for precise location authorization, If user hasn't given it, ask for one time permission.
    /// - Parameter completion: completion callback.
    func checkAndRequestForAccuracyAuthorizationIfNeeded(_ completion: ((Bool) -> Void)?)

    /// Update settings of the hardware based on running requests.
    /// - Parameter newSettings: settings.
    func updateSettings(_ newSettings: LocationManagerSettings)
    
    /// Activate geofence per requests.
    /// - Parameter requests: requests.
    func geofenceRegions(_ requests: [GeofencingRequest])
    
    /// Start monitoring beacon regions.
    /// - Parameter regions: regions.
    func monitorBeaconRegions(_ regions: [CLBeaconRegion])
    
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
        case beacon

        public var description: String {
            rawValue
        }
    }
    
    // MARK: - Public Properties
    
    /// Active CoreLocation services to activate.
    public internal(set) var activeServices = Set<Services>()
    
    /// Accuracy needed.
    public internal(set) var accuracy: GPSLocationOptions.Accuracy = .any
    
    /// Minimum distance.
    public internal(set) var minDistance: CLLocationDistance = kCLDistanceFilterNone
    
    /// Activity type.
    public internal(set) var activityType: CLActivityType = .other
    
    /// Precise location (only iOS 14+)
    public internal(set) var precise: GPSLocationOptions.Precise = .reducedAccuracy
    
    public func requireLocationUpdates() -> Bool {
        return
            activeServices.contains(.continousLocation) ||
            activeServices.contains(.significantLocation) ||
            activeServices.contains(.visits)
    }
    
    public var description: String {
        let data: [String: Any] = [
            "services": activeServices.description,
            "accuracy": accuracy.description,
            "minDistance": minDistance,
            "activityType": activityType.description,
            "precise": precise.description
        ]
        return JSONStringify(data)
    }
    
}
