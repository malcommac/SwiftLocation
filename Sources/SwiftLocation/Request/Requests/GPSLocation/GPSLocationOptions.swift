//
//  GPSLocationOptions.swift
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
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

/// NOTE: In iOS14+ we are using kCLLocationAccuracyReduced instead.
internal let CLLocationAccuracyAccuracyAny: CLLocationAccuracy = 6000 // 6km or more

public class GPSLocationOptions: CustomStringConvertible, Codable {
    
    /// Determine the accuracy of location. This settings is introduced in iO14.
    public enum Precise: Comparable {
        case reducedAccuracy
        case fullAccuracy

        public static var all: [Precise] {
            return [.fullAccuracy, .reducedAccuracy]
        }
        
        public var description: String {
            switch self {
            case .fullAccuracy:     return "fullAccuracy"
            case .reducedAccuracy:  return "reducedAccuracy"
            }
        }
        
        public var value: CLAccuracyAuthorization {
            switch self {
            case .fullAccuracy:
                return .fullAccuracy
            case .reducedAccuracy:
                return .reducedAccuracy
            }
        }
        
        @available(iOS 14.0, *)
        static func fromCLAccuracyAuthorization(_ accuracy: CLAccuracyAuthorization) -> Precise {
            switch accuracy {
            case .reducedAccuracy: return .reducedAccuracy
            default: return .fullAccuracy
            }
        }
        
    }
    
    /// Type of subscription.
    ///
    /// - `single`: single one shot subscription. After receiving the first data request did end.
    /// - `continous`: continous subscription. You must end it manually.
    /// - `significant`: only significant location changes are received from the underlying service.
    ///                 You should use it when you don't need high-precision/high-frequency data
    ///                 and you want to preserve battery life.
    public enum Subscription: String, Codable {
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
    public enum Timeout: CustomStringConvertible, Codable {
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
            case .delayed:   return SwiftLocation.authorizationStatus.isAuthorized
            }
        }
        
        public var description: String {
            switch self {
            case .immediate(let t): return "immediate \(abs(t))s"
            case .delayed(let t):   return "delayed \(abs(t))s"
            }
        }
        
        private var kind: Int {
            switch self {
            case .delayed: return 0
            case .immediate: return 1
            }
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case kind, interval
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            try container.encode(interval, forKey: .interval)
        }
        
        // Decodable protocol
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Int.self, forKey: .kind)
            let interval = try container.decode(TimeInterval.self, forKey: .interval)
            
            switch kind {
            case 0: self = .delayed(interval)
            case 1: self = .immediate(interval)
            default: fatalError("Failed to decode Timeout")
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
    public enum Accuracy: Comparable, CustomStringConvertible, Codable {
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
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case value
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }
        
        // Decodable protocol
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(CLLocationAccuracy.self, forKey: .value)
            self = Accuracy(rawValue: value)
        }
        
    }
    
    /// Associated request.
    public weak var request: GPSLocationRequest?
    
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
    
    /// Specify level of accuracy required for task. If user does not have precise location on, it will ask for one time permission..
    /// By default is not set and the choice of the user is set; you can set to `.fullAccuracy` to eventually request one
    /// time permission to the user when is set the `.reducedAccuracy` level for the app.
    /// In this case remember to set the appropriate `NSLocationTemporaryUsageDescriptionDictionary` info key into app Info.plist.
    /// 
    /// NOTE: Only for iOS 14 or later.
    public var precise: Precise?
    
    /// Timeout level, by default is `nil` which means no timeout policy is set and you must end the request manually.
    public var timeout: Timeout?
    
    /// Activity type to better manage the location reporting; by default is set to `other`.
    public var activityType: CLActivityType = .other
    
    /// Minimum horizontal distance to report new fresh data.
    /// By default is set to `kCLDistanceFilterNone` which means client will be informed of any movement.
    public var minDistance: CLLocationDistance = kCLDistanceFilterNone

    /// Minimum time interval since last valid received data to report new fresh data.
    /// By default is set to `nil` which means no filter is applied.
    public var minTimeInterval: TimeInterval?
    
    /// Description of the options.
    public var description: String {
        return "{" + [
            "subscription= \(subscription)",
            "accuracy= \(accuracy)",
            "precise= \(precise?.description ?? "user's set")",
            "timeout= \(timeout?.description ?? "none")",
            "activityType= \(activityType)",
            "minDistance= \(minDistance)",
            "minTimeInterval= \(minTimeInterval ?? 0)"
        ].joined(separator: ", ") + "}"
    }
    
    // MARK: - Initialization
    
    public init() {

    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case avoidRequestAuthorization, subscription, accuracy, timeout, activityType, minTimeInterval, minDistance
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(avoidRequestAuthorization, forKey: .avoidRequestAuthorization)
        try container.encode(subscription, forKey: .subscription)
        try container.encode(accuracy, forKey: .accuracy)
        try container.encodeIfPresent(timeout, forKey: .timeout)
        try container.encode(activityType.rawValue, forKey: .activityType)
        try container.encodeIfPresent(minTimeInterval, forKey: .minTimeInterval)
        try container.encodeIfPresent(minDistance, forKey: .minDistance)
    }
    
    // Decodable protocol
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    
        self.avoidRequestAuthorization = try container.decode(Bool.self, forKey: .avoidRequestAuthorization)
        self.subscription = try container.decode(Subscription.self, forKey: .subscription)
        self.accuracy = try container.decode(Accuracy.self, forKey: .accuracy)
        self.timeout = try container.decodeIfPresent(Timeout.self, forKey: .timeout)
        self.activityType = try CLActivityType(rawValue: container.decode(Int.self, forKey: .activityType)) ?? .other
        self.minTimeInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .minTimeInterval)
        self.minDistance = try container.decodeIfPresent(CLLocationDistance.self, forKey: .minDistance) ?? kCLDistanceFilterNone
    }
    
}
