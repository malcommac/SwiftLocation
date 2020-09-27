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
    
    // MARK: - Initialization Google Maps
    
    init?(googleJSON json: [String: Any]?) {
        guard let json = json else { return nil }
        
        self.representedObject = json
        
        let name: String? = json.valueForKeyPath(keyPath: "formatted_address")
        self.info[.name] = name
        
        let lat: CLLocationDegrees? = json.valueForKeyPath(keyPath: "geometry.location.lat")
        let lng: CLLocationDegrees? = json.valueForKeyPath(keyPath: "geometry.location.lng")
        self.coordinates = CLLocationCoordinate2D(latitude: lat ?? 0, longitude: lng ?? 0)
        
        let id: String? = json.valueForKeyPath(keyPath: "place_id")
        self.info[.id] = id
        
        let country: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["country"], key: "long_name")
        let countryCode: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["country"], key: "short_name")
        let locality: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["locality"], key: "long_name")
        let administrativeArea: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_1"], key: "long_name")
        let subAdministrativeArea: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["administrative_area_level_2"], key: "long_name")
        let throughfare: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["neighborhood", "route"], key: "long_name")
        let postalCode: String? = GeocoderLocation.addComponentValueForTypes(json, allowedTypes: ["postal_code"], key: "long_name")
        let locationType: String? = json.valueForKeyPath(keyPath: "geometry.location_type")

        self.info[.country] = country
        self.info[.countryCode] = countryCode
        self.info[.locality] = locality
        self.info[.administrativeArea] = administrativeArea
        self.info[.subAdministrativeArea] = subAdministrativeArea
        self.info[.throughfare] = throughfare
        self.info[.postalCode] = postalCode
        self.info[.locationType] = locationType
        
        self.region = nil
        self.timezone = nil
    }
    
    static func fromGoogleList(_ data: Data) throws -> [GeocoderLocation] {
        let rawObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        // Parsing errors.
        guard let rawDict = rawObj as? [String: Any],
              let rawStatus: String = rawDict.valueForKeyPath(keyPath: "status") else {
            throw LocatorErrors.parsingError
        }
    
        // Non valid response which generate errors.
        if let resultError = GoogleStatusResponse(rawValue: rawStatus)?.error {
            throw resultError
        }
        
        guard let rawResults: [[String: Any]]? = rawDict.valueForKeyPath(keyPath: "results") else {
            return []
        }
        
        return rawResults?.compactMap({ GeocoderLocation(googleJSON: $0) }) ?? []
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

internal extension GeocoderLocation {
    
    fileprivate enum GoogleStatusResponse: String {
        case ok = "OK"
        case noResult = "ZERO_RESULTS"
        case dailyQuotaReached = "OVER_DAILY_LIMIT"
        case queryQuotaReached = "OVER_QUERY_LIMIT"
        case requestDenied = "REQUEST_DENIED"
        case invalidRequest = "INVALID_REQUEST"
        case other = "UNKNOWN_ERROR"
        
        var error: LocatorErrors? {
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
