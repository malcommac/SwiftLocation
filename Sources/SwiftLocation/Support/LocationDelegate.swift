import Foundation
import CoreLocation

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    private weak var asyncBridge: LocationAsyncBridge?
    
    init(asyncBridge: LocationAsyncBridge) {
        self.asyncBridge = asyncBridge
        super.init()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.didChangeAuthorization(manager.authorizationStatus))
        asyncBridge?.dispatchEvent(.didChangeAccuracyAuthorization(manager.accuracyAuthorization))
        locationManagerDidChangeServicesEnabled()
    }
    
    private func locationManagerDidChangeServicesEnabled() {
        Task {
            let enabled = CLLocationManager.locationServicesEnabled()
            await MainActor.run {
                asyncBridge?.dispatchEvent(.didChangeLocationEnabled(enabled))
            }
        }
    }
    
    // MARK: - Location Updates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        asyncBridge?.dispatchEvent(.receiveNewLocations(locations: locations))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        asyncBridge?.dispatchEvent(.didFailWithError(error))
    }
    
    // MARK: - Heading Updates
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        asyncBridge?.dispatchEvent(.didUpdateHeading(newHeading))
    }
    
    // MARK: - Pause/Resume

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesPaused)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesResumed)
    }
    
    // MARK: - Region Monitoring
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        asyncBridge?.dispatchEvent(.monitoringDidFailFor(region: region, error: error))
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        asyncBridge?.dispatchEvent(.didEnterRegion(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        asyncBridge?.dispatchEvent(.didExitRegion(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        asyncBridge?.dispatchEvent(.didStartMonitoringFor(region))
    }
    
    // MARK: - Visits Monitoring
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        asyncBridge?.dispatchEvent(.didVisit(visit: visit))
    }
        
    // MARK: - Beacons Ranging
        
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        asyncBridge?.dispatchEvent(.didRange(beacons: beacons, constraint: beaconConstraint))
    }
        
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        asyncBridge?.dispatchEvent(.didFailRanginFor(constraint: beaconConstraint, error: error))
    }
    
}
