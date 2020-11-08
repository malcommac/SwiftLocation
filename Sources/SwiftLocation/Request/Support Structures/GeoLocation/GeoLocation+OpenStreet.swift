//
//  GeoLocation+OpenStreet.swift
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

// MARK: - GeocoderLocation Google Initialization

internal extension GeoLocation {
    
    init?(openStreetJSON json: [String: Any]?) {
        guard let json = json else { return nil }
        
        let placeID: Int? = json.valueForKeyPath(keyPath: "place_id")
        let locationType: String? = json.valueForKeyPath(keyPath: "addresstype")
        let type: String? = json.valueForKeyPath(keyPath: "type")
        let osmID: Int? = json.valueForKeyPath(keyPath: "osm_id")
        let osmType: String? = json.valueForKeyPath(keyPath: "osm_type")
        let name: String? = json.valueForKeyPath(keyPath: "name")
        let nameDetails: String? = json.valueForKeyPath(keyPath: "namedetails.name")
        let formattedName: String? = json.valueForKeyPath(keyPath: "display_name")
        let country: String? = json.valueForKeyPath(keyPath: "address.country")
        let county: String? = json.valueForKeyPath(keyPath: "address.county")
        let countryCode: String? = json.valueForKeyPath(keyPath: "address.country_code")
        let postalCode: String? = json.valueForKeyPath(keyPath: "address.postcode")
        let throughfare: String? = json.valueForKeyPath(keyPath: "address.neighbourhood")
        let locality: String? = json.valueForKeyPath(keyPath: "address.city")
        let administrativeArea: String? = json.valueForKeyPath(keyPath: "address.state")
        let subAdministrativeArea: String? = json.valueForKeyPath(keyPath: "address.county")
        let subAdministrativeArea3: String? = json.valueForKeyPath(keyPath: "address.city_block")
        let streetAddress: String? = json.valueForKeyPath(keyPath: "address.road")
        let placeRank: Int? = json.valueForKeyPath(keyPath: "place_rank")
        let village: String? = json.valueForKeyPath(keyPath: "address.village")

        let lat: String? = json.valueForKeyPath(keyPath: "lat")
        let lng: String? = json.valueForKeyPath(keyPath: "lon")
        self.coordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat ?? "0") ?? 0, longitude: CLLocationDegrees(lng ?? "0") ?? 0)
        
        self.info[.id] = (placeID != nil ? String(placeID!) : nil)

        self.info[.country] = country
        self.info[.countryCode] = countryCode
        
        self.info[.locationType] = locationType ?? type
        self.info[.osmID] = (osmID != nil ? String(osmID!) : nil)
        self.info[.osmType] = osmType
        self.info[.name] = name ?? nameDetails
        self.info[.formattedAddress] = formattedName
        self.info[.throughfare] = throughfare ?? village
        self.info[.postalCode] = postalCode
        self.info[.administrativeArea] = administrativeArea
        self.info[.subAdministrativeArea] = subAdministrativeArea
        self.info[.subAdministrativeArea3] = subAdministrativeArea3
        self.info[.locality] = locality ?? county
        self.info[.streetAddress] = streetAddress
        self.info[.placeRank] = (placeRank != nil ? String(placeRank!) : nil)

        self.region = nil
        self.timezone = nil
    }
    
    static func fromOpenStreetList(_ data: Data) throws -> [GeoLocation] {
        let rawJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        guard let rawResults = rawJSON as? [[String: Any]] else {
            throw LocationError.parsingError
        }
        
        return rawResults.compactMap({ GeoLocation(openStreetJSON: $0 )})
    }
    
}
