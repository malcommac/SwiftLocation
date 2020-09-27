//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

// MARK: - GeocoderLocation Google Initialization

internal extension GeocoderLocation {
    
    init?(openStreetJSON json: [String: Any]?) {
        guard let json = json else { return nil }
        
        let placeID: Int? = json.valueForKeyPath(keyPath: "place_id")
        let locationType: String? = json.valueForKeyPath(keyPath: "osm_type")
        let osmID: String? = json.valueForKeyPath(keyPath: "osm_id")
        let name: String? = json.valueForKeyPath(keyPath: "name")
        let formattedName: String? = json.valueForKeyPath(keyPath: "display_name")
        let country: String? = json.valueForKeyPath(keyPath: "address.country")
        let countryCode: String? = json.valueForKeyPath(keyPath: "address.country_code")
        let postalCode: String? = json.valueForKeyPath(keyPath: "address.postcode")

        let lat: String? = json.valueForKeyPath(keyPath: "lat")
        let lng: String? = json.valueForKeyPath(keyPath: "lon")
        self.coordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat ?? "0") ?? 0, longitude: CLLocationDegrees(lng ?? "0") ?? 0)
        
        self.info[.id] = (placeID != nil ? String(placeID!) : nil)
        self.info[.locationType] = locationType
        self.info[.osmID] = osmID
        self.info[.name] = name
        self.info[.formattedAddress] = formattedName
        self.info[.country] = country
        self.info[.countryCode] = countryCode
        self.info[.postalCode] = postalCode
        
        self.region = nil
        self.timezone = nil
    }
    
    static func fromOpenStreetList(_ data: Data) throws -> [GeocoderLocation] {
        let rawJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        guard let rawResults = rawJSON as? [[String: Any]] else {
            throw LocatorErrors.parsingError
        }
        
        return rawResults.compactMap({ GeocoderLocation(openStreetJSON: $0 )})
    }
    
}
