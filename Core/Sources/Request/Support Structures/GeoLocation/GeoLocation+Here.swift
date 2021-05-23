//
//  GeoLocation+Here.swift
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
