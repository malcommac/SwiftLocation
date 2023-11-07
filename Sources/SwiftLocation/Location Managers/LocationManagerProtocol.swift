import Foundation
import CoreLocation

/// The `CLLocationManager` implementation used to provide a mocked version
/// of the system location manager used to write tests.
public protocol LocationManagerProtocol {
    
    // MARK: - Delegate
    
    var delegate: CLLocationManagerDelegate? { get set }
    
    // MARK: - Authorization
    
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    var activityType: CLActivityType { get set }
    var distanceFilter: CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    func locationServicesEnabled() -> Bool
    
    // MARK: - Location Permissions
    
    func validatePlistConfigurationOrThrow(permission: LocationPermission) throws
    func validatePlistConfigurationForTemporaryAccuracy(purposeKey: String) throws
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)?)

    // MARK: - Getting Locations
    
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()

    // MARK: - Monitoring Regions
    
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    
    // MARK: - Monitoring Visits
    
    func startMonitoringVisits()
    func stopMonitoringVisits()
    
    // MARK: - Monitoring Significant Location Changes
    
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    
    // MARK: - Getting Heading

    func startUpdatingHeading()
    func stopUpdatingHeading()
    
    // MARK: - Beacon Ranging
    
    func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint)
    func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint)

}
