//
//  CLLocationManager+Extras.swift
//  SwiftLocation
//
//  Created by dan on 14/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation

public extension CLLocationManager {
    
    enum AuthorizationMode {
        case viaInfoPlist
        case whenInUse
        case always
    }
    
    /// Return `true` if host application has background location capabilities enabled
    static var hasBackgroundCapabilities: Bool {
        guard let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
            return false
        }
        return capabilities.contains("location")
    }
    
    internal func requestAuthorizationIfNeeded(_ mode: AuthorizationMode) {
        switch mode {
        case .viaInfoPlist:
            requestViaPList()
        case .whenInUse:
            self.requestWhenInUseAuthorization()
        case .always:
            self.requestAlwaysAuthorization()
        }
    }
    
    private func requestViaPList() {
        // Determines which level of permissions to request based on which description key is present in your app's Info.plist
        // If you provide values for both description keys, the more permissive "Always" level is requested.
        let iOSVersion = floor(NSFoundationVersionNumber)
        let isiOS7To10 = (iOSVersion >= NSFoundationVersionNumber_iOS_7_1 && Int32(iOSVersion) <= NSFoundationVersionNumber10_11_Max)
        
        guard LocationManager.state == .undetermined else {
            return // no need to ask
        }
        
        var canRequestAlways = false
        var canRequestWhenInUse = false
        
        if isiOS7To10 {
            canRequestAlways = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil
            canRequestWhenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        } else {
            canRequestAlways = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil
            canRequestWhenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        }
        
        if canRequestAlways {
            requestAlwaysAuthorization()
        } else if canRequestWhenInUse {
            requestWhenInUseAuthorization()
        } else {
            if isiOS7To10 {
                // At least one of the keys NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription
                // MUST be present in the Info.plist file to use location services on iOS 8+.
                assert(canRequestAlways || canRequestWhenInUse, "To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.")
            } else {
                // Key NSLocationAlwaysAndWhenInUseUsageDescription MUST be present in the Info.plist file
                // to use location services on iOS 11+.
                assert(canRequestAlways, "To use location services in iOS 11+, your Info.plist must provide a value for NSLocationAlwaysAndWhenInUseUsageDescription.")
            }
        }
    }
    
}
