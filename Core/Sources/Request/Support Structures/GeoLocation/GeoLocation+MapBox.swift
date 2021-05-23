//
//  GeoLocation+MapBox.swift
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
