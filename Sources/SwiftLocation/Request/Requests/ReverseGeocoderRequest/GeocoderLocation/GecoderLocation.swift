//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public struct GeocoderLocation: CustomStringConvertible {
    
    public enum Keys {
        case id // unique identifier
        case name // formatted name
        case countryCode
        case country
        case postalCode
        case administrativeArea
        case subAdministrativeArea
        case locality
        case subLocality
        case throughfare
        case subThroughfare
        case locationType
    }
    
    public let coordinates: CLLocationCoordinate2D
    
    /// Represented object. It's CLPlacemark when using Apple services, or a Dictionary with raw json data for any other external service.
    public internal(set) var representedObject: Any?
    
    /// The geographic region associated with the placemark.
    public let region: CLRegion?
    
    /// he time zone associated with the placemark.
    public let timezone: TimeZone?
    
    /// If available the CLPlacemark instance which originate this location.
    public var clPlacemark: CLPlacemark? {
        representedObject as? CLPlacemark
    }
    
    /// Additional data.
    public internal(set) var info = [Keys: String?]()
    
    // MARK: - Public Methods
    
    public var description: String {
        return "{ coordinates=\(coordinates), name=\(String(describing: self.info[.name] ?? "")) }"
    }
    
}
