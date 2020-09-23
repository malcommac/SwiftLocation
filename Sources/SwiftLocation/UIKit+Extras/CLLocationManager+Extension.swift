//
//  CLLocationManager+Extension.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

// MARK: - CLLocation

internal extension CLLocation {
    
    static func mostRecentsTimeStampCompare(_ loc1: CLLocation, loc2: CLLocation) -> Bool {
        return loc1.timestamp > loc2.timestamp
    }
 
    var accuracy: LocationOptions.Accuracy {
        LocationOptions.Accuracy(rawValue: horizontalAccuracy)
    }
    
}

// MARK: - CLLocationManager

internal extension CLLocationManager {
    
    // MARK: - Internal Variables
    
    static func hasBackgroundCapabilities() -> Bool {
        guard let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
            return false
        }
        return capabilities.contains("location")
    }
    
    // MARK: - Internal Functions
    
    func requestAuthorization(_ mode: AuthorizationMode) {
        switch mode {
        case .always:       requestAlwaysAuthorization()
        case .onlyInUse:    requestWhenInUseAuthorization()
        case .plist:        requestPlistAuthorization()
        }
    }
    
    func setSettings(_ settings: LocationManagerSettings) {
        self.desiredAccuracy = settings.accuracy.value
        self.activityType = settings.activityType
        self.distanceFilter = settings.minDistance ?? kCLLocationAccuracyThreeKilometers
        
        // Location updates
        let hasContinousLocation = settings.activeServices.contains(.continousLocation)
        if hasContinousLocation {
            startUpdatingLocation()
        } else {
            stopUpdatingLocation()
        }
        
        // Significant locations
        let hasSignificantLocation = settings.activeServices.contains(.significantLocation)
        if hasSignificantLocation {
            startMonitoringSignificantLocationChanges()
        } else {
            stopMonitoringSignificantLocationChanges()
        }
    }
    
    // MARK: - Private Functions
    
    private func requestPlistAuthorization() {
        guard authorizationStatus != .notDetermined else {
            return
        }
        
        let alwaysIsEnabled = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil
        let onlyInUseEnabled = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        
        if alwaysIsEnabled {
            requestAlwaysAuthorization()
        } else if onlyInUseEnabled {
            requestWhenInUseAuthorization()
        }
    }
    
}

// MARK: - CLAuthorizationStatus

internal extension CLAuthorizationStatus {
    
    var isAuthorized: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
}
