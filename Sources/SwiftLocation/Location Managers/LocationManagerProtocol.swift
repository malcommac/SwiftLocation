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

/// The `CLLocationManager` implementation used to provide a mocked version
/// of the system location manager used to write tests.
public protocol LocationManagerProtocol {
    
    // MARK: - Delegate
    
    var delegate: CLLocationManagerDelegate? { get set }
    
    // MARK: - Authorization
    
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    
    #if !os(tvOS)
    var activityType: CLActivityType { get set }
    #endif
    
    var distanceFilter: CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    
    #if !os(tvOS) && !os(visionOS)
    var allowsBackgroundLocationUpdates: Bool { get set }
    #endif
    
    func locationServicesEnabled() -> Bool
    
    // MARK: - Location Permissions
    
    func validatePlistConfigurationOrThrow(permission: LocationPermission) throws
    func validatePlistConfigurationForTemporaryAccuracy(purposeKey: String) throws
    func requestWhenInUseAuthorization()
    
    #if !os(tvOS) && !os(visionOS)
    func requestAlwaysAuthorization()
    #endif
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)?)

    // MARK: - Getting Locations
    
    #if !os(tvOS)
    func startUpdatingLocation()
    func stopUpdatingLocation()
    #endif
    func requestLocation()

    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    // MARK: - Monitoring Regions
    
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    #endif
    
    // MARK: - Monitoring Visits
    
    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    func startMonitoringVisits()
    func stopMonitoringVisits()
    #endif

    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    // MARK: - Monitoring Significant Location Changes
    
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
    #endif
    
    #if os(iOS)
    // MARK: - Getting Heading

    func startUpdatingHeading()
    func stopUpdatingHeading()
    #endif
    
    // MARK: - Beacon Ranging
    
    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint)
    func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint)
    #endif
}
