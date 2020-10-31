//
//  CLLocationManager+Extension.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation
import MapKit
import Contacts

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
        case .always:
            requestAlwaysAuthorization()
        case .onlyInUse:
            requestWhenInUseAuthorization()
        case .plist:
            requestPlistAuthorization()
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
        
        // Significant Locations
        let hasSignificantLocation = settings.activeServices.contains(.significantLocation)
        if hasSignificantLocation {
            startMonitoringSignificantLocationChanges()
        } else {
            stopMonitoringSignificantLocationChanges()
        }
        
        // Visits
        if settings.activeServices.contains(.visits) {
            startMonitoringVisits()
        } else {
            stopMonitoringVisits()
        }
    }
    
    // MARK: - Private Functions
    
    private func requestPlistAuthorization() {
        if #available(iOS 14.0, *) {
            guard authorizationStatus == .notDetermined else {
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

// MARK: - CLPlacemark

extension CLPlacemark {
    
    /// Formatted address
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress)
    }
    
}

// MARK: - CLLocationCoordinate2D

extension CLLocationCoordinate2D: Codable {
   
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
     
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
    
}

// MARK: - MKCoordinateSpan

extension MKCoordinateSpan: Codable {
   
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitudeDelta)
        try container.encode(longitudeDelta)
    }
     
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitudeDelta: latitude, longitudeDelta: longitude)
    }
    
}

// MARK: - MKMultiPoint

extension MKMultiPoint {
    
    /// Get the coordinates of the polygon
    public var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
    
}

// MARK: - MKPolygon

extension MKPolygon {
    
    /// Coordinates is inside the polygon.
    ///
    /// - Parameter location: coordinates to check.
    /// - Returns: Bool
    internal func containsCoordinate(_ location: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let mapPoint = MKMapPoint(location)
        let polygonPoint = polygonRenderer.point(for: mapPoint)
        
        return polygonRenderer.path.contains(polygonPoint)
    }
    
    /// Return the outer circle which contains the polygon.
    /// - Returns: MKCircle.
    public func outerCircle() -> MKCircle? {
        guard let center = centroidForCoordinates(coordinates) else {
            return nil
        }
        
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        var maxDistance = CLLocationDistance(0)
        for point in coordinates {
            let distanceToCenter = CLLocation(latitude: point.latitude, longitude: point.longitude).distance(from: centerLocation)
            maxDistance = max(maxDistance, distanceToCenter)
        }
        
        let inscribedCircle = MKCircle(center: center, radius: maxDistance)
        return inscribedCircle
    }
    
    // MARK: - Internal Helper Functions
    
    /// Return the centroid of a polygon.
    ///
    /// - Parameter coords: coordinates lsit.
    /// - Returns: CLLocationCoordinate2D
    private func centroidForCoordinates(_ coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard let firstCoordinate = coordinates.first else {
            return nil
        }
        
        guard coords.count > 1 else {
            return firstCoordinate
        }
        
        var minX = firstCoordinate.longitude
        var maxX = firstCoordinate.longitude
        var minY = firstCoordinate.latitude
        var maxY = firstCoordinate.latitude
        
        for i in 1..<coords.count {
            let current = coords[i]
            if minX > current.longitude {
                minX = current.longitude
            } else if maxX < current.longitude {
                maxX = current.longitude
            } else if minY > current.latitude {
                minY = current.latitude
            } else if maxY < current.latitude {
                maxY = current.latitude
            }
        }
        
        let centerX = minX + ((maxX - minX) / 2)
        let centerY = minY + ((maxY - minY) / 2)
        return CLLocationCoordinate2D(latitude: centerY, longitude: centerX)
    }
    
}
