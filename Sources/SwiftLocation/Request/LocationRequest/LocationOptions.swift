//
//  LocationOptions.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 18/09/2020.
//

import Foundation
import CoreLocation

/// NOTE: In iOS14+ we are using kCLLocationAccuracyReduced instead.
internal let CLLocationAccuracyAccuracyAny: CLLocationAccuracy = 6000 // 6km or more

public class LocationOptions: CustomStringConvertible {
    
    /// Type of subscription.
    ///
    /// - `single`: single one shot subscription. After receiving the first data request did end.
    /// - `continous`: continous subscription. You must end it manually.
    /// - `significant`: only significant location changes are received from the underlying service.
    ///                 You should use it when you don't need high-precision/high-frequency data
    ///                 and you want to preserve battery life.
    public enum Subscription: String {
        case single
        case continous
        case significant
        
        internal var service: LocationManagerSettings.Services {
            switch self {
            case .single, .continous:
                return .continousLocation
            case .significant:
                return .significantLocation
            }
        }
        
        public var description: String {
            rawValue
        }
    }
    
    /// The timeout policy of the request.
    ///
    /// - `immediate`: timeout countdown starts immediately after the request is added regardless the current authorization level.
    /// - `delayed`: timeout countdown starts only after the required authorization are granted from the user.
    public enum Timeout: CustomStringConvertible {
        case immediate(TimeInterval)
        case delayed(TimeInterval)
        
        public var interval: TimeInterval {
            switch self {
            case .immediate(let t): return t
            case .delayed(let t):   return t
            }
        }
        
        /// Can start timer.
        /// Timer can be started always if immediate, only if it has authorization when delayed.
        internal var canFireTimer: Bool {
            switch self {
            case .immediate: return true
            case .delayed:   return Locator.shared.authorizationStatus.isAuthorized
            }
        }
        
        public var description: String {
            switch self {
            case .immediate(let t): return "immediate \(t)s"
            case .delayed(let t):   return "delayed \(t)s"
            }
        }
    }
    
    /// Accuracy level.
    /// You must be careful selecting the level, depending of the zone a strict level may reduce or zero the received data.
    ///
    /// - `any`: no filter is set for accuracy level, all data received from sensor are reported to the requrst.
    /// - `city`: only data with accuracy of <= 5km in the last 10 mins are reported.
    /// - `neighborhood`: only data with accuracy of <= 1km in the last 5 mins are reported.
    /// - `block`: only data with accuracy of <= 100mts in the last 1 mins are reported.
    /// - `house`: only data with accuracy of <= 60mts in the last 40s are reported.
    /// - `room`: only data with accuracy of <= 25mts in the last 40s are reported.
    /// - `custom`: only data with custom level of accuracy are reported.
    public enum Accuracy: Comparable, CustomStringConvertible {
        case any
        case city
        case neighborhood
        case block
        case house
        case room
        case custom(CLLocationAccuracy)
        
        public init(rawValue: CLLocationAccuracy) {
            guard rawValue > -1 else {
                self = .any
                return
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
                if #available(iOS 14.0, *) {
                    self = (rawValue == kCLLocationAccuracyReduced ? .any : .custom(rawValue))
                } else {
                    self = (rawValue == CLLocationAccuracyAccuracyAny ? .any : .custom(rawValue))
                }
            }
        }
        
        public static func < (lhs: Accuracy, rhs: Accuracy) -> Bool {
            return lhs.value < rhs.value
        }
        
        /// Accuracy expressed in meters for each value.
        public var value: CLLocationAccuracy {
            switch self {
            case .any:
            if #available(iOS 14.0, *) {
                return kCLLocationAccuracyReduced
            } else {
                return CLLocationAccuracyAccuracyAny
            }
            case .city:         return 5000
            case .neighborhood: return 1000
            case .block:        return 100
            case .house:        return 60
            case .room:         return 25
            case .custom(let v):return v
            }
        }
        
        public var description: String {
            switch self {
            case .any:              return "any"
            case .city:             return "city"
            case .neighborhood:     return "neighborhood"
            case .block:            return "block"
            case .house:            return "house"
            case .room:             return "room"
            case .custom(let v):    return "custom(\(v)"
            }
        }
    }
    
    /// Associated request.
    public weak var request: LocationRequest?
    
    /// Avoid request authorization. If this value is set to true and authorization is not granted by the user
    /// the request fails with `authorizationNeeded` error.
    /// By default it's set to `false`.
    ///
    /// NOTE: If other requests into the queue require authorization the location manager always ask for it.
    public var avoidRequestAuthorization = false
    
    /// Subscription level, by default is set to `continous`.
    public var subscription: Subscription = .single
    
    /// Accuracy level, by default is set to `any`.
    public var accuracy: Accuracy = .any
    
    /// Timeout level, by default is `nil` which means no timeout policy is set and you must end the request manually.
    public var timeout: Timeout?
    
    /// Activity type to better manage the location reporting; by default is set to `other`.
    public var activityType: CLActivityType = .other
    
    /// Minimum horizontal distance to report new fresh data.
    /// By default is set to `nil` which means no filter is applied.
    public var minDistance: CLLocationDistance?
    
    /// Minimum time interval since last valid received data to report new fresh data.
    /// By default is set to `nil` which means no filter is applied.
    public var minTimeInterval: TimeInterval?
    
    /// Description of the options.
    public var description: String {
        return "{" + [
            "subscription= \(subscription)",
            "accuracy= \(accuracy)",
            "timeout= \(timeout?.description ?? "none")",
            "activityType= \(activityType)",
            "minDistance= \(minDistance ?? -1)",
            "minTimeInterval= \(minTimeInterval ?? 0)"
        ].joined(separator: ", ") + "}"
    }
    
}
