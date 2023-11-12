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
    public var onRequestValidationForTemporaryAccuracy: ((String) -> Error?) = { _ in return nil }

    public func updateLocations(event: Tasks.ContinuousUpdateLocation.StreamEvent) {
        switch event {
        case let .didUpdateLocations(locations):
            delegate?.locationManager?(fakeInstance, didUpdateLocations: locations)
        case .didResume:
            delegate?.locationManagerDidResumeLocationUpdates?(fakeInstance)
        case .didPaused:
            delegate?.locationManagerDidPauseLocationUpdates?(fakeInstance)
        case let .didFailed(error):
            delegate?.locationManager?(fakeInstance, didFailWithError: error)
        }
    }
    
    public func updateSignificantLocation(event: Tasks.SignificantLocationMonitoring.StreamEvent) {
        switch event {
        case let .didFailWithError(error):
            delegate?.locationManager?(fakeInstance, didFailWithError: error)
        case .didPaused:
            delegate?.locationManagerDidPauseLocationUpdates?(fakeInstance)
        case .didResume:
            delegate?.locationManagerDidResumeLocationUpdates?(fakeInstance)
        case let .didUpdateLocations(locations):
            delegate?.locationManager?(fakeInstance, didUpdateLocations: locations)
        }
    }
    
    public func updateVisits(event: Tasks.VisitsMonitoring.StreamEvent) {
        switch event {
        case let .didVisit(visit):
            delegate?.locationManager?(fakeInstance, didVisit: visit)
        case let .didFailWithError(error):
            delegate?.locationManager?(fakeInstance, didFailWithError: error)
        }
    }
    
    public func updateRegionMonitoring(event: Tasks.RegionMonitoring.StreamEvent) {
        switch event {
        case let .didEnterTo(region):
            delegate?.locationManager?(fakeInstance, didEnterRegion: region)
            
        case let .didExitTo(region):
            delegate?.locationManager?(fakeInstance, didExitRegion: region)
            
        case let .didStartMonitoringFor(region):
            delegate?.locationManager?(fakeInstance, didStartMonitoringFor: region)
            
        case let .monitoringDidFailFor(region, error):
            delegate?.locationManager?(fakeInstance, monitoringDidFailFor: region, withError: error)
            
        }
    }
    
    public func validatePlistConfigurationForTemporaryAccuracy(purposeKey: String) throws {
        if let error = onRequestValidationForTemporaryAccuracy(purposeKey) {
            throw error
        }
    }
    
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
        self.accuracyAuthorization = .fullAccuracy
        completion?(nil)
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
