//
//  GeoLocation+Google.swift
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
    
    init?(googleJSON json: [String: Any]?) {
        guard let json = json else { return nil }
        
        self.representedObject = json
        
        let name: String? = json.valueForKeyPath(keyPath: "formatted_address")
        self.info[.name] = name
        self.info[.formattedAddress] = name

        let lat: CLLocationDegrees? = json.valueForKeyPath(keyPath: "geometry.location.lat")
        let lng: CLLocationDegrees? = json.valueForKeyPath(keyPath: "geometry.location.lng")
        self.coordinates = CLLocationCoordinate2D(latitude: lat ?? 0, longitude: lng ?? 0)
        
        let id: String? = json.valueForKeyPath(keyPath: "place_id")
        self.info[.id] = id
        
        let country: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["country"], key: "long_name")
        let countryCode: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["country"], key: "short_name")
        let locality: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["locality"], key: "long_name")
        let administrativeArea: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_1"], key: "long_name")
        let subAdministrativeArea: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_2"], key: "long_name")
        let subAdministrativeArea3: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_3"], key: "long_name")
        let subAdministrativeArea4: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_4"], key: "long_name")
        let subAdministrativeArea5: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_5"], key: "long_name")
        let throughfare: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["neighborhood", "route"], key: "long_name")
        let postalCode: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["postal_code"], key: "long_name")
        let streetAddress: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["street_address"], key: "long_name")
        let intersection: String? = GeoLocation.addComponentValueForTypes(json, allowedTypes: ["intersection"], key: "long_name")
        let locationType: String? = json.valueForKeyPath(keyPath: "geometry.location_type")
        
        self.info[.country] = country
        self.info[.countryCode] = countryCode
        self.info[.locality] = locality
        self.info[.administrativeArea] = administrativeArea
        self.info[.subAdministrativeArea] = subAdministrativeArea
        self.info[.subAdministrativeArea3] = subAdministrativeArea3
        self.info[.subAdministrativeArea4] = subAdministrativeArea4
        self.info[.subAdministrativeArea5] = subAdministrativeArea5
        self.info[.throughfare] = throughfare
        self.info[.postalCode] = postalCode
        self.info[.locationType] = locationType
        self.info[.intersection] = intersection
        self.info[.streetAddress] = streetAddress
        
        self.region = nil
        self.timezone = nil
    }
    
    static func fromGoogleSingle(_ data: Data) throws -> GeoLocation? {
        let rawJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let json = rawJson as? [String: Any],
              let result: [String: Any] = json.valueForKeyPath(keyPath: "result") else {
            return nil
        }
        
        return GeoLocation(googleJSON: result)
    }
    
    static func fromGoogleList(_ data: Data) throws -> [GeoLocation] {
        let rawObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        // Parsing errors.
        guard let rawDict = rawObj as? [String: Any],
              let rawStatus: String = rawDict.valueForKeyPath(keyPath: "status") else {
            throw LocationError.parsingError
        }
    
        // Non valid response which generate errors.
        if let resultError = GoogleStatusResponse(rawValue: rawStatus)?.error {
            throw resultError
        }
        
        guard let rawResults: [[String: Any]]? = rawDict.valueForKeyPath(keyPath: "results") else {
            return []
        }
        
        return rawResults?.compactMap({ GeoLocation(googleJSON: $0) }) ?? []
    }
    
    // MARK: - Helper Functions
    
    /// Search inside the address_components node of the Google Maps response for a specific item which has the at least one of the allowedTypes.
    /// When found extract from that dictionary passed key.
    ///
    /// - Parameters:
    ///   - json: json array source.
    ///   - allowedTypes: allowed types.
    ///   - key: key to get the value.
    /// - Returns: String?
    static func addComponentValueForTypes(_ json: [String: Any], allowedTypes: [String], key: String) -> String? {
        guard let components: [[String: Any]] = json.valueForKeyPath(keyPath: "address_components") else {
            return nil
        }
        
        let allowedTypesSet = Set(allowedTypes)
        guard let rawType = components.first(where: {
            guard let itemTypes: [String] = $0.valueForKeyPath(keyPath: "types") else {
                return false
            }
            
            let itemTypesSet = Set(itemTypes)
            // Returns true if the two specified collections have no elements in common.
            return itemTypesSet.isDisjoint(with: allowedTypesSet) == false
        }) else {
            return nil
        }
        
        return rawType.valueForKeyPath(keyPath: key)
    }
    
}

// MARK: - GeocoderLocation GoogleStatusResponse

internal extension GeoLocation {
    
    fileprivate enum GoogleStatusResponse: String {
        case ok = "OK"
        case noResult = "ZERO_RESULTS"
        case dailyQuotaReached = "OVER_DAILY_LIMIT"
        case queryQuotaReached = "OVER_QUERY_LIMIT"
        case requestDenied = "REQUEST_DENIED"
        case invalidRequest = "INVALID_REQUEST"
        case other = "UNKNOWN_ERROR"
        
        var error: LocationError? {
            switch self {
            case .ok, .noResult:
                return nil
            case .dailyQuotaReached, .queryQuotaReached:
                return .usageLimitReached
            default:
                return .other(rawValue)
            }
        }
        
    }
    
}
