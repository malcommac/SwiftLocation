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

// MARK: - Accuracy Filters

/// A set of accuracy filters.
public typealias AccuracyFilters = [AccuracyFilter]

extension AccuracyFilters {
    
    /// Return the highest value of the accuracy level used as filter
    /// in both horizontal and vertical direction.
    static func highestAccuracyLevel(currentLevel: CLLocationAccuracy = kCLLocationAccuracyReduced, filters: AccuracyFilters?) -> CLLocationAccuracy {
        guard let filters else { return currentLevel }
        
        var value: Double = currentLevel
        for filter in filters {
            switch filter {
            case let .vertical(vValue):
                value = Swift.min(value, vValue)
            case let .horizontal(hValue):
                value = Swift.min(value, hValue)
            default:
                break
            }
        }
        return value
    }
    
}

/// Single Accuracy filter.
public enum AccuracyFilter {
    /// Filter for the altitude values, and their estimated uncertainty, measured in meters.
    case horizontal(CLLocationAccuracy)
    /// Filter for the radius of uncertainty for the location, measured in meters.
    case vertical(CLLocationAccuracy)
    /// Filter for the accuracy of the speed value, measured in meters per second.
    case speed(CLLocationSpeedAccuracy)
    /// Filter for the accuracy of the course value, measured in degrees.
    case course(CLLocationDirectionAccuracy)
    /// Filter using a custom function.
    case custom(_ isIncluded: ((CLLocation) -> Bool))
                
    // MARK: - Internal Functions
    
    /// Return a filtered array of the location which match passed filters.
    ///
    /// - Parameters:
    ///   - locations: initial array of locations.
    ///   - filters: filters to validate.
    /// - Returns: filtered locations.
    static func filteredLocations(_ locations: [CLLocation], withAccuracyFilters filters: AccuracyFilters?) -> [CLLocation] {
        guard let filters else { return locations }
        return locations.filter { AccuracyFilter.isLocation($0, validForFilters: filters) }
    }
    
    /// Return if location is valid for a given set of accuracy filters.
    ///
    /// - Parameters:
    ///   - location: location to validate.
    ///   - filters: filters used for check.
    /// - Returns: `true` if location respect filters passed.
    static func isLocation(_ location: CLLocation, validForFilters filters: AccuracyFilters) -> Bool {
        let firstInvalidFilter = filters.first { $0.isValidForLocation(location) == false }
        let isValid = (firstInvalidFilter == nil)
        return isValid
    }
    
    /// Return if location match `self` filter.
    ///
    /// - Parameter location: location to check.
    /// - Returns: `true` if accuracy is valid for given location.
    private func isValidForLocation(_ location: CLLocation) -> Bool {
        switch self {
        case let .horizontal(value):
            return location.horizontalAccuracy <= value
        case let .vertical(value):
            return location.verticalAccuracy <= value
        case let .speed(value):
            return location.speedAccuracy <= value
        case let .course(value):
            return location.courseAccuracy <= value
        case let .custom(isIncluded):
            return isIncluded(location)
        }
    }
    
}

// MARK: - Location Accuracy

/// Accuracy level you can set for the location manager.
public enum LocationAccuracy {
    /// The highest level of accuracy 
    /// (available only if precise location authorization is granted).
    case best
    /// Accurate to within ten meters of the desired target 
    /// (available only if precise location authorization is granted).
    case nearestTenMeters
    /// Accurate to within one hundred meters.
    /// (available only if precise location authorization is granted).
    case hundredMeters
    /// Accurate to the nearest kilometer.
    /// (available only if precise location authorization is granted).
    case kilometer
    /// Accurate to the nearest three kilometers.
    /// (available only if precise location authorization is granted).
    case threeKilometers
    /// The highest possible accuracy that uses additional sensor data to facilitate navigation apps.
    /// (available only if precise location authorization is granted).
    case bestForNavigation
    /// Custom precision, may require precise location authorization.
    case custom(Double)
    
    init(level: CLLocationAccuracy) {
        switch level {
        case kCLLocationAccuracyBest:                 self = .best
        case kCLLocationAccuracyNearestTenMeters:     self = .nearestTenMeters
        case kCLLocationAccuracyHundredMeters:        self = .hundredMeters
        case kCLLocationAccuracyKilometer:            self = .kilometer
        case kCLLocationAccuracyThreeKilometers:      self = .threeKilometers
        case kCLLocationAccuracyBestForNavigation:    self = .bestForNavigation
        default:                                      self = .custom(level)
        }
    }
    
    internal var level: CLLocationAccuracy {
        switch self {
        case .best:                 return kCLLocationAccuracyBest
        case .nearestTenMeters:     return kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:        return kCLLocationAccuracyHundredMeters
        case .kilometer:            return kCLLocationAccuracyKilometer
        case .threeKilometers:      return kCLLocationAccuracyThreeKilometers
        case .bestForNavigation:    return kCLLocationAccuracyBestForNavigation
        case .custom(let value):    return value
        }
    }
}

// MARK: - LocationPermission

public enum LocationPermission {
    /// Always authorization, both background and when in use.
    #if !os(tvOS) && !os(visionOS)
    case always
    #endif
    /// Only when in use authorization.
    case whenInUse
}
