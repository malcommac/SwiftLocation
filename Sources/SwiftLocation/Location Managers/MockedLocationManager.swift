import Foundation
import CoreLocation

public class MockedLocationManager: LocationManagerProtocol {
    public func requestAlwaysAuthorization() {
        
    }
    
    public var authorizationStatus: CLAuthorizationStatus {
        .authorizedAlways
    }
    
    public weak var delegate: CLLocationManagerDelegate?
    
    public func locationServicesEnabled() -> Bool {
        false
    }
    
    public var desiredAccuracy: CLLocationAccuracy = 100.0
    public var activityType: CLActivityType = .other
    public var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    public var allowsBackgroundLocationUpdates: Bool = false
    
    public var accuracyAuthorization: CLAccuracyAuthorization {
        .fullAccuracy
    }
    
    public func requestWhenInUseAuthorization() {
        
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
