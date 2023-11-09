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
        case .always:
            if !Bundle.hasAlwaysPermission() {
                throw LocationErrors.plistNotConfigured
            }
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
            "fullAccuracy"
        case .reducedAccuracy:
            "reducedAccuracy"
        @unknown default:
            "Unknown (\(rawValue))"
        }
    }
    
}

extension CLAuthorizationStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notDetermined:        "notDetermined"
        case .restricted:           "restricted"
        case .denied:               "denied"
        case .authorizedAlways:     "authorizedAlways"
        case .authorizedWhenInUse:  "authorizedWhenInUse"
        @unknown default:           "unknown"
        }
    }
    
    var canMonitorLocation: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            true
        default:
            false
        }
    }
    
}

// MARK: - Foundation Extensions

extension Bundle {
    
    private static let always = "NSLocationAlwaysUsageDescription"
    private static let whenInUse = "NSLocationAlwaysAndWhenInUseUsageDescription"
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
    
    static func hasAlwaysPermission() -> Bool {
        !(Bundle.main.object(forInfoDictionaryKey: always) as? String ?? "").isEmpty &&
        !( Bundle.main.object(forInfoDictionaryKey: whenInUse) as? String ?? "").isEmpty
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

