import Foundation
import CoreLocation
@testable import SwiftLocation

public class MockedLocationManager: LocationManagerProtocol {
    
    let fakeInstance = CLLocationManager()
    public weak var delegate: CLLocationManagerDelegate?

    public var allowsBackgroundLocationUpdates: Bool = false
    
    public var isLocationServicesEnabled: Bool = true {
        didSet {
            guard isLocationServicesEnabled != oldValue else { return }
            delegate?.locationManagerDidChangeAuthorization?(fakeInstance)
        }
    }
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined {
        didSet {
            guard authorizationStatus != oldValue else { return }
            delegate?.locationManagerDidChangeAuthorization?(fakeInstance)
        }
    }
    
    public var accuracyAuthorization: CLAccuracyAuthorization = .reducedAccuracy {
        didSet {
            guard accuracyAuthorization != oldValue else { return }
            delegate?.locationManagerDidChangeAuthorization?(fakeInstance)
        }
    }

    public var desiredAccuracy: CLLocationAccuracy = 100.0
    public var activityType: CLActivityType = .other
    public var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    
    public var onValidatePlistConfiguration: ((_ permission: LocationPermission) -> Error?) = { _ in
        return nil
    }
    
    public var onRequestWhenInUseAuthorization: (() -> CLAuthorizationStatus) = { .notDetermined }
    public var onRequestAlwaysAuthorization: (() -> CLAuthorizationStatus) = { .notDetermined }

    public func validatePlistConfigurationOrThrow(permission: LocationPermission) throws {
        if let error = onValidatePlistConfiguration(permission) {
            throw error
        }
    }
    
    public func locationServicesEnabled() -> Bool {
        isLocationServicesEnabled
    }
    
    public func requestAlwaysAuthorization() {
        self.authorizationStatus = onRequestAlwaysAuthorization()
    }
    
    public func requestWhenInUseAuthorization() {
        self.authorizationStatus = onRequestWhenInUseAuthorization()
    }
    
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)? = nil) {
        
    }
    
    public func startUpdatingLocation() {
        
    }
    
    public func stopUpdatingLocation() {
        
    }
    
    public func requestLocation() {
        
    }
    
    public func startMonitoring(for region: CLRegion) {
        
    }
    
    public func stopMonitoring(for region: CLRegion) {
        
    }
    
    public func startMonitoringVisits() {
        
    }
    
    public func stopMonitoringVisits() {
        
    }
    
    public func startMonitoringSignificantLocationChanges() {
        
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        
    }
    
    public func startUpdatingHeading() {
        
    }
    
    public func stopUpdatingHeading() {
        
    }
    
    public func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
        
    }
    
    public func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
    
    }
    
    public init() {
        
    }
}
