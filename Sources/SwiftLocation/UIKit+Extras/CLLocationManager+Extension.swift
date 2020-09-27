//
//  CLLocationManager+Extension.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

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
        
        debugPrint("SETTING DESIDERED ACCURACY \(settings.accuracy.value)")
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
        if #available(iOS 14.0, *) {
            guard authorizationStatus != .notDetermined else {
                return
            }
        } else {
            guard CLLocationManager.authorizationStatus() == .notDetermined else {
                return
            }
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

extension CLAuthorizationStatus: CustomStringConvertible {
    
    internal var isAuthorized: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .notDetermined:            return "notDetermined"
        case .restricted:               return "restricted"
        case .denied:                   return "denied"
        case .authorizedAlways:         return "always"
        case .authorizedWhenInUse:      return "whenInUse"
        @unknown default:               return "unknown"
        }
    }
    
}

// MARK: - CLActivityType

extension CLActivityType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .other:                return "other"
        case .automotiveNavigation: return "automotiveNavigation"
        case .fitness:              return "fitness"
        case .otherNavigation:      return "otherNavigation"
        case .airborne:             return "airbone"
        @unknown default:           return "unknown"
        }
    }

}

// MARK: - CLLocation

internal extension CLLocation {
    
    static func mostRecentsTimeStampCompare(_ loc1: CLLocation, loc2: CLLocation) -> Bool {
        return loc1.timestamp > loc2.timestamp
    }
 
    var accuracy: GPSLocationOptions.Accuracy {
        GPSLocationOptions.Accuracy(rawValue: horizontalAccuracy)
    }
    
}
