//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation
import CoreLocation

// MARK: - GeocoderLocation Google Initialization

internal extension GeoLocation {
    
    // MARK: - Initialization Google Maps
    
    init?(hereJSON json: [String: Any]?) {
        guard let json = json else {
            return nil
        }
        
        self.representedObject = json
        
        self.region = nil
        self.timezone = nil

        let lat: CLLocationDegrees? = json.valueForKeyPath(keyPath: "position.lat")
        let lng: CLLocationDegrees? = json.valueForKeyPath(keyPath: "position.lng")
        guard let latitude = lat, let longitude = lng else {
            return nil
        }
        
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let id: String? = json.valueForKeyPath(keyPath: "id")
        let name: String? = json.valueForKeyPath(keyPath: "title")
        let formattedAddress: String? = json.valueForKeyPath(keyPath: "address.label")
        let locationType: String? = json.valueForKeyPath(keyPath: "resultType")
        let countryCode: String? = json.valueForKeyPath(keyPath: "address.countryCode")
        let postalCode: String? = json.valueForKeyPath(keyPath: "address.postalCode")
        let streetAddress: String? = json.valueForKeyPath(keyPath: "address.street")
        let locality: String? = json.valueForKeyPath(keyPath: "address.city")
        let subAdministrativeArea: String? = json.valueForKeyPath(keyPath: "address.county")
        let administrativeArea: String? = json.valueForKeyPath(keyPath: "address.state")

        info[.id] = id
        info[.name] = name
        info[.formattedAddress] = formattedAddress
        info[.locationType] = locationType
        info[.countryCode] = countryCode
        info[.postalCode] = postalCode
        info[.streetAddress] = streetAddress
        info[.locality] = locality
        info[.subAdministrativeArea] = subAdministrativeArea
        info[.administrativeArea] = administrativeArea
    }
    
    static func fromHereList(_ raw: [[String: Any]]?) -> [GeoLocation] {
        raw?.compactMap({
            GeoLocation(hereJSON: $0)
        }) ?? []
    }
    
}
