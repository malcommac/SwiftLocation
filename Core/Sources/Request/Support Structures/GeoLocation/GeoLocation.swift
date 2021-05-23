//
//  GeoLocation.swift
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

public struct GeoLocation: CustomStringConvertible {
    
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
        case osmType// OSM type
        case placeRank // Ranking
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
        let infoDictionary = info.enumerated().map {
            "\($0.element.key) = '\($0.element.value ?? "")'"
        }.joined(separator: "\n\t")
        return "{ \n\tcoordinates = lat:\(coordinates.latitude),lng:\(coordinates.longitude),\n\tname=\(String(describing: self.info[.name] ?? ""))\n\t\(infoDictionary)\n}"
    }
    
}
