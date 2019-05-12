//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import CoreLocation

internal let CLLocationAccuracyAccuracyAny: CLLocationAccuracy = 6000 // 6km or more

public extension LocationManager {
    
    /// Errors of the location manager.
    ///
    /// - cancelled: operation was cancelled by the user.
    /// - timeout: timeout reached.
    /// - invalidAuthStatus: invalid authorization status.
    /// - generic: generic error.
    /// - noData: no data received from service.
    /// - missingAPIKey: missing required api key for service.
    /// - requiredLocationNotFound: required accurated location were not found, last found reported.
    enum ErrorReason: Error {
        case cancelled
        case timeout(TimeInterval)
        case invalidAuthStatus(CLAuthorizationStatus)
        case generic(String)
        case noData(URL?)
        case missingAPIKey
        case requiredLocationNotFound(timeout: TimeInterval, last: CLLocation?)
    }
    
    enum State: CustomStringConvertible {
        case available
        case undetermined
        case denied
        case restricted
        case disabled
        
        public var description: String {
            switch self {
            case .available:    return "available"
            case .undetermined: return "undetermined"
            case .denied:       return "denied"
            case .restricted:   return "restricted"
            case .disabled:     return "disabled"
            }
        }
    }
    
    enum Accuracy: Comparable, CustomStringConvertible {
        case any
        case city
        case neighborhood
        case block
        case house
        case room
        case custom(CLLocationAccuracy)
        
        public static var all: [Accuracy] {
            return [.any, .city, .neighborhood, .block, .house, .room]
        }
        
        public static func < (lhs: LocationManager.Accuracy, rhs: LocationManager.Accuracy) -> Bool {
            return lhs.value < rhs.value
        }
        
        public init?(rawValue: CLLocationAccuracy) {
            guard rawValue > -1 else {
                return nil
            }
            switch rawValue {
            case Accuracy.city.value:
                self = .city
            case Accuracy.neighborhood.value:
                self = .neighborhood
            case Accuracy.block.value:
                self = .block
            case Accuracy.house.value:
                self = .house
            case Accuracy.room.value:
                self = .room
            default:
                if rawValue == CLLocationAccuracyAccuracyAny {
                    self = .any
                } else {
                    self = .custom(rawValue)
                }
            }
        }
        
        public var value: CLLocationAccuracy {
            switch self {
            case .any:
                return CLLocationAccuracyAccuracyAny
            case .city:
                return 5000
            case .neighborhood:
                return 1000
            case .block:
                return 100
            case .house:
                return 15
            case .room:
                return 5
            case .custom(let value):
                return value
            }
        }
        
        public var interval: TimeInterval {
            switch self {
            case .city:
                return 600.0
            case .neighborhood:
                return 300.0
            case .block:
                return 60.0
            case .house:
                return 15.0
            case .room:
                return 5.0
            default:
                return TimeInterval.greatestFiniteMagnitude
            }
        }
        
        public var description: String {
            switch self {
            case .any:
                return "any"
            case .city:
               return "city"
            case .neighborhood:
                return "neighborhood"
            case .block:
                return "block"
            case .house:
                return "house"
            case .room:
                return "room"
            default:
                return NSString(format: "%0.0fmt, %0.0fs", self.value, self.interval) as String
            }
        }
        
    }
}
