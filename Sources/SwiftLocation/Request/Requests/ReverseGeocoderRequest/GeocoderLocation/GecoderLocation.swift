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
        case name // name
        case formattedAddress // formatted complete address
        case countryCode // 2-digit country code
        case country // indicates the national political entity, and is typically the highest order type returned by the Geocoder.
        case postalCode //  indicates a postal code as used to address postal mail within the country.
        case administrativeArea // indicates a first-order civil entity below the country level
        case subAdministrativeArea //  indicates a second-order civil entity below the country level
        case subAdministrativeArea3 //  indicates a third-order civil entity below the country level
        case subAdministrativeArea4 //  indicates a fourth-order civil entity below the country level.
        case subAdministrativeArea5 //  ndicates a fifth-order civil entity below the country level.
        case locality // indicates an incorporated city or town political entity.
        case intersection // indicates a major intersection, usually of two major roads.
        case subLocality // indicates a first-order civil entity below a locality.
        case throughfare // indicates a named neighborhood
        case subThroughfare // Additional street-level information for the placemark.
        case locationType // type of location separated by |
        case streetAddress // indicates a precise street address.
        case POI // area of interests separated by |.
        case osmID // OSM identifier
    }
    
    /// Coordinates of the location.
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
