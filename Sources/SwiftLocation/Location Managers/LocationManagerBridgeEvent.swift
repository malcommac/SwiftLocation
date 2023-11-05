import Foundation
import CoreLocation

public enum LocationManagerBridgeEvent {
    
    // MARK: - Authorization
    
    case didChangeLocationEnabled(_ enabled: Bool)
    case didChangeAuthorization(_ status: CLAuthorizationStatus)
    case didChangeAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)

    // MARK: - Location Monitoring
    
    case locationUpdatesPaused
    case locationUpdatesResumed
    case receiveNewLocations(locations: [CLLocation])
    
    // MARK: - Region Monitoring
    
    case didEnterRegion(_ region: CLRegion)
    case didExitRegion(_ region: CLRegion)
    case didStartMonitoringFor(_ region: CLRegion)

    // MARK: - Failures
    
    case didFailWithError(_ error: Error)
    case monitoringDidFailFor(region: CLRegion?, error: Error)

    // MARK: - Visits Monitoring

    case didVisit(visit: CLVisit)
    
    // MARK: - Headings
    
    case didUpdateHeading(_ heading: CLHeading)
    
    // MARK: - Beacons
    
    case didRange(beacons: [CLBeacon], constraint: CLBeaconIdentityConstraint)
    case didFailRanginFor(constraint: CLBeaconIdentityConstraint, error: Error)

}
