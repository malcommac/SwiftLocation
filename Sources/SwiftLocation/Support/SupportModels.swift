import Foundation
import CoreLocation

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

public enum AccuracyFilter {
    case horizontal(CLLocationAccuracy)
    case vertical(CLLocationAccuracy)
    case speed(CLLocationSpeedAccuracy)
    case course(CLLocationDirectionAccuracy)
    
    static func filteredLocations(_ locations: [CLLocation], withAccuracyFilters filters: AccuracyFilters?) -> [CLLocation] {
        guard let filters else { return locations }
        return locations.filter { AccuracyFilter.isLocation($0, validForFilters: filters) }
    }
    
    static func isLocation(_ location: CLLocation, validForFilters filters: AccuracyFilters) -> Bool {
        filters.first { $0.isValidForLocation(location) == false } != nil
    }
    
    private func isValidForLocation(_ location: CLLocation) -> Bool {
        switch self {
        case let .horizontal(value):
            location.horizontalAccuracy >= value
        case let .vertical(value):
            location.verticalAccuracy >= value
        case let .speed(value):
            location.speedAccuracy >= value
        case let .course(value):
            location.courseAccuracy >= value
        }
    }
    
}

public enum LocationAccuracy {
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
    case bestForNavigation
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
        case .best:                 kCLLocationAccuracyBest
        case .nearestTenMeters:     kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:        kCLLocationAccuracyHundredMeters
        case .kilometer:            kCLLocationAccuracyKilometer
        case .threeKilometers:      kCLLocationAccuracyThreeKilometers
        case .bestForNavigation:    kCLLocationAccuracyBestForNavigation
        case .custom(let value):    value
        }
    }
}

public enum LocationPermission {
    case always
    case whenInUse
}
