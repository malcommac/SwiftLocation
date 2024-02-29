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

// MARK: - CoreLocation Extensions

extension CLLocationManager: LocationManagerProtocol {
    
    public func locationServicesEnabled() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
 
    /// Evaluate the `Info.plist` file data and throw exceptions in case of misconfiguration.
    ///
    /// - Parameter permission: permission you would to obtain.
    public func validatePlistConfigurationOrThrow(permission: LocationPermission) throws {
        switch permission {
        #if !os(tvOS)
        case .always:
            if !Bundle.hasAlwaysAndWhenInUsePermission() {
                throw LocationErrors.plistNotConfigured
            }
        #endif
        case .whenInUse:
            if !Bundle.hasWhenInUsePermission() {
                throw LocationErrors.plistNotConfigured
            }
        }
    }
    
    public func validatePlistConfigurationForTemporaryAccuracy(purposeKey: String) throws {
        guard Bundle.hasTemporaryPermission(purposeKey: purposeKey) else {
            throw LocationErrors.plistNotConfigured
        }
    }
    
}

extension CLAccuracyAuthorization: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .fullAccuracy:
            return "fullAccuracy"
        case .reducedAccuracy:
            return "reducedAccuracy"
        @unknown default:
            return "Unknown (\(rawValue))"
        }
    }
    
}

extension CLAuthorizationStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notDetermined:        return "notDetermined"
        case .restricted:           return "restricted"
        case .denied:               return "denied"
        case .authorizedAlways:     return "authorizedAlways"
        case .authorizedWhenInUse:  return "authorizedWhenInUse"
        @unknown default:           return "unknown"
        }
    }
    
    var canMonitorLocation: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
}

// MARK: - Foundation Extensions

extension Bundle {
    
    private static let alwaysAndWhenInUse = "NSLocationAlwaysAndWhenInUseUsageDescription"
    private static let whenInUse = "NSLocationWhenInUseUsageDescription"
    private static let temporary = "NSLocationTemporaryUsageDescriptionDictionary"
    
    static func hasTemporaryPermission(purposeKey: String) -> Bool {
        guard let node = Bundle.main.object(forInfoDictionaryKey: temporary) as? NSDictionary,
              let value = node.object(forKey: purposeKey) as? String,
              value.isEmpty == false else {
            return false
        }
        return true
    }
    
    static func hasWhenInUsePermission() -> Bool {
        !(Bundle.main.object(forInfoDictionaryKey: whenInUse) as? String ?? "").isEmpty
    }
    
    static func hasAlwaysAndWhenInUsePermission() -> Bool {
        !(Bundle.main.object(forInfoDictionaryKey: alwaysAndWhenInUse) as? String ?? "").isEmpty
    }
    
}

extension UserDefaults {
        
    func set(location:CLLocation?, forKey key: String) {
        guard let location else {
            removeObject(forKey: key)
            return
        }
        
        let locationData = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false)
        set(locationData, forKey: key)
    }
    
    func location(forKey key: String) -> CLLocation? {
        guard let locationData = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: locationData)
        } catch {
            return nil
        }
    }
    
}

