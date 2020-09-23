//
//  CLLocationManagerAware.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

public protocol LocationManagerDelegate: class {
    func locationManager(didFailWithError error: Error)
    func locationManager(didReceiveLocations locations: [CLLocation])
}

public protocol LocationManagerProtocol: class {
    typealias AuthorizationCallback = ((CLAuthorizationStatus) -> Void)

    var authorizationStatus: CLAuthorizationStatus { get }
    var delegate: LocationManagerDelegate? { get set }

    init(locator: Locator) throws

    func requestAuthorization(_ mode: AuthorizationMode, _ callback: @escaping AuthorizationCallback)
    
    func updateSettings(_ newSettings: LocationManagerSettings)
    
}

enum Monitors {
    case significantLocation
    case continousLocation
}

public enum AuthorizationMode {
    case plist
    case always
    case onlyInUse
}

public struct LocationManagerSettings {
    
    public enum Services {
        case continousLocation
        case significantLocation
    }
    
    var activeServices: Set<Services>
    var accuracy: LocationOptions.Accuracy = .any
    var minDistance: CLLocationDistance?
    var activityType: CLActivityType = .other
    
    public init(activeServices: Set<Services>) {
        self.activeServices = activeServices
    }
    
    public func requireLocationUpdates() -> Bool {
        return activeServices.contains(.continousLocation) ||
                activeServices.contains(.significantLocation)
    }
    
}
