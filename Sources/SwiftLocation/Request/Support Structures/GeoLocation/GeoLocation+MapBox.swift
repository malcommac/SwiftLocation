//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation
import CoreLocation

internal extension GeoLocation {
    
    // MARK: - Initialization Google Maps
    
    init?(mapBoxJSON json: [String: Any]?) {
        guard let json = json else { return nil }
        
        self.representedObject = json
        
        self.region = nil
        self.timezone = nil

        let coordinates: [CLLocationDegrees]? = json.valueForKeyPath(keyPath: "geometry.coordinates")
        guard let lat = coordinates?.first, let lng = coordinates?.last else {
            return nil
        }
        self.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        let id: String? = json.valueForKeyPath(keyPath: "id")
        let name: String? = json.valueForKeyPath(keyPath: "text")
        let formattedAddress: String? = json.valueForKeyPath(keyPath: "place_name")

        let country: String? = GeoLocation.parseAddressComponents(json, startWith: "country.")
        let administrativeArea: String? = GeoLocation.parseAddressComponents(json, startWith: "region.")
        let subAdministrativeArea: String? = GeoLocation.parseAddressComponents(json, startWith: "place")
        let locality: String? = GeoLocation.parseAddressComponents(json, startWith: "locality.")
        let postalCode: String? = GeoLocation.parseAddressComponents(json, startWith: "postcode")
        let streetAddress: String? = GeoLocation.parseAddressComponents(json, startWith: "neighborhood")
        let locationType: [String]? = json.valueForKeyPath(keyPath: "place_type")

        info[.id] = id
        info[.name] = name
        info[.country] = country
        info[.formattedAddress] = formattedAddress
        info[.administrativeArea] = administrativeArea
        info[.subAdministrativeArea] = subAdministrativeArea
        info[.locality] = locality
        info[.postalCode] = postalCode
        info[.streetAddress] = streetAddress
        info[.locationType] = locationType?.joined(separator: ";")
    }
    
    static func fromMapBoxList(_ raw: [[String: Any]]?) -> [GeoLocation] {
        raw?.compactMap({
            GeoLocation(mapBoxJSON: $0)
        }) ?? []
    }

    static func parseAddressComponents(_ json: [String: Any], startWith: String) -> String? {
        guard let list: [[String: Any]]? = json.valueForKeyPath(keyPath: "context") else {
            return nil
        }
        
        return list?.first { rawItem in
            guard let id: String? = rawItem.valueForKeyPath(keyPath: "id") else {
                return false
            }
            
            return id?.starts(with: startWith) ?? false
        }?.valueForKeyPath(keyPath: "text")
    }
    
}
