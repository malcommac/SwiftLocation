//
//  SwiftLocation
//  Async/Await Wrapper for CoreLocation
//
//  Copyright (c) 2023 Daniele Margutti (hello@danielemargutti.com).
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

/// This is the class which receive events from the `LocationManagerProtocol` implementation
/// and dispatch to the bridged tasks.
final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    private weak var asyncBridge: LocationAsyncBridge?
    
    private var locationManager: LocationManagerProtocol {
        asyncBridge!.location!.locationManager
    }
    
    init(asyncBridge: LocationAsyncBridge) {
        self.asyncBridge = asyncBridge
        super.init()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.didChangeAuthorization(locationManager.authorizationStatus))
        asyncBridge?.dispatchEvent(.didChangeAccuracyAuthorization(locationManager.accuracyAuthorization))
        asyncBridge?.dispatchEvent(.didChangeLocationEnabled(locationManager.locationServicesEnabled()))
    }
    
    // MARK: - Location Updates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        asyncBridge?.dispatchEvent(.receiveNewLocations(locations: locations))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        asyncBridge?.dispatchEvent(.didFailWithError(error))
    }
    
    // MARK: - Heading Updates
    
    #if os(iOS)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        asyncBridge?.dispatchEvent(.didUpdateHeading(newHeading))
    }
    #endif
    
    #if os(iOS)
    // MARK: - Pause/Resume

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesPaused)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesResumed)
    }
    #endif
    
    // MARK: - Region Monitoring
    
    #if os(iOS)
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
    #endif
    
    // MARK: - Visits Monitoring
    
    #if os(iOS)
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        asyncBridge?.dispatchEvent(.didVisit(visit: visit))
    }
    #endif
    
    #if os(iOS)
    // MARK: - Beacons Ranging
        
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        asyncBridge?.dispatchEvent(.didRange(beacons: beacons, constraint: beaconConstraint))
    }
        
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        asyncBridge?.dispatchEvent(.didFailRanginFor(constraint: beaconConstraint, error: error))
    }
    #endif
    
}
