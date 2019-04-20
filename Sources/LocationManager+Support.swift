//
//  LocationManager+Support.swift
//  SwiftLocation
//
//  Created by dan on 18/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation

public extension LocationManager {
    
    enum ErrorReason: Error {
        case cancelled
        case timeout(TimeInterval)
        case invalidAuthStatus(CLAuthorizationStatus)
        case generic(String)
        case noData(URL?)
        case missingAPIKey
    }
    
    enum State {
        case available
        case undetermined
        case denied
        case restricted
        case disabled
    }
    
    enum Accuracy: Comparable {
        case any
        case city
        case neighborhood
        case block
        case house
        case room
        case custom(CLLocationAccuracy)
        
        public static func < (lhs: LocationManager.Accuracy, rhs: LocationManager.Accuracy) -> Bool {
            return lhs.value < rhs.value
        }
        
        public init(rawValue: CLLocationAccuracy) {
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
                if rawValue != 0 {
                    self = .custom(rawValue)
                } else {
                    self = .any
                }
            }
        }
        
        public var value: CLLocationAccuracy {
            switch self {
            case .any:
                return Double.greatestFiniteMagnitude
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
        
    }
}
