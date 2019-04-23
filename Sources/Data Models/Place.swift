//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import CoreLocation
import Contacts
import MapKit

public class Place {

    public private(set) var placemark: CLPlacemark?
    public private(set) var name: String?
    public private(set) var coordinates: CLLocationCoordinate2D?

    public private(set) var state: String?
    public private(set) var county: String?
    public private(set) var neighborhood: String?
    public private(set) var city: String?
    public private(set) var country: String?
    public private(set) var isoCountryCode: String?
    public private(set) var postalCode: String?
    public private(set) var streetNumber: String?
    public private(set) var streetAddress: String?
    public private(set) var formattedAddress: String?
    public private(set) var areasOfInterest: [String]?

    public private(set) var region: CLRegion?
    public private(set) var timezone: TimeZone?
    public private(set) var postalAddress: CNPostalAddress?
    public private(set) var addressDictionary: [AnyHashable: Any]?

    // MARK: - Initialization -
    
    internal init(openStreet json: Any) {
        // Coordinates
        if let lat: String = valueAtKeyPath(root: json, ["lat"]),
            let lng: String = valueAtKeyPath(root: json, ["lon"]) {
            self.coordinates = CLLocationCoordinate2DMake(CLLocationDegrees(lat) ?? 0, CLLocationDegrees(lng) ?? 0)
        }
        
        self.formattedAddress = valueAtKeyPath(root: json, ["display_name"])
        self.name = valueAtKeyPath(root: json, ["address29"])
        self.state = valueAtKeyPath(root: json, ["address","country"])
        self.isoCountryCode = valueAtKeyPath(root: json, ["address","country_code"])
        self.city = valueAtKeyPath(root: json, ["address","city"])
        self.postalCode = valueAtKeyPath(root: json, ["address","postcode"])
        self.neighborhood = valueAtKeyPath(root: json, ["address","neighbourhood"])
        self.streetAddress = valueAtKeyPath(root: json, ["address","road"])
        self.streetNumber = valueAtKeyPath(root: json, ["address","house_number"])
        self.county = valueAtKeyPath(root: json, ["address","county"])
        self.country = valueAtKeyPath(root: json, ["address","country"])

        self.placemark = Place.clPlacemarkFromPlace(self)
        self.postalAddress = Place.cnPostalAddressFromPlace(self)
    }
    
    /// Initialize from map item.
    ///
    /// - Parameter mapItem: map item.
    internal convenience init(mapItem: MKMapItem) {
        self.init(placemark: mapItem.placemark)
    }
    
    /// Initialize a new place object from google's JSON response.
    ///
    /// - Parameter json: json response.
    internal init(googleJSON json: Any) {
        
        // Address components
        let abComponents: [[String: Any]] = valueAtKeyPath(root: json, ["address_components"]) ?? []
        
        func abWithType(_ type: String) -> [String:Any]? {
            return abComponents.first(where: { node in
                guard let types: [String] = valueAtKeyPath(root: node, ["types"]) else {
                    return false
                }
                return types.contains(type)
            })
        }
        
        func abValue(inType type: String, path: [String]) -> String? {
            guard let node: [String:Any] = abWithType(type) else {
                return nil
            }
            return valueAtKeyPath(root: node, path)
        }
        
        // Coordinates
        if let lat: Double = valueAtKeyPath(root: json, ["geometry","location","lat"]),
            let lng: Double = valueAtKeyPath(root: json, ["geometry","location","lng"]) {
            self.coordinates = CLLocationCoordinate2DMake(lat, lng)
        }
        
        self.formattedAddress = valueAtKeyPath(root: json, ["formatted_address"])
        self.name = abValue(inType: "establishment", path: ["long_name"])
        self.state = abValue(inType: "administrative_area_level_1", path: ["long_name"])
        self.county = abValue(inType: "administrative_area_level_2", path: ["long_name"])
        self.country = abValue(inType: "country", path: ["long_name"])
        self.isoCountryCode = abValue(inType: "country", path: ["short_name"])
        self.neighborhood = abValue(inType: "neighborhood", path: ["long_name"])
        self.city = abValue(inType: "locality", path: ["long_name"]) ?? abValue(inType: "sublocality", path: ["long_name"])
        self.postalCode = abValue(inType: "postal_code", path: ["long_name"])
        self.streetNumber = abValue(inType: "street_number", path: ["long_name"])
        self.streetAddress = abValue(inType: "route", path: ["long_name"])
        self.formattedAddress = valueAtKeyPath(root: json, ["formatted_address"])

        if let area = abValue(inType: "point_of_interest", path: ["long_name"]) {
            self.areasOfInterest = [area]
        }
        
        self.placemark = Place.clPlacemarkFromPlace(self)
        self.postalAddress = Place.cnPostalAddressFromPlace(self)
    }
    
    /// Initialize a new place from `CLPlacemark` instance.
    ///
    /// - Parameter placemark: instance of the placemark.
    internal init(placemark: CLPlacemark) {
        self.placemark = placemark
        self.name = placemark.name
        self.isoCountryCode = placemark.isoCountryCode
        self.country = placemark.country
        self.postalCode = placemark.postalCode
        self.state = placemark.administrativeArea
        self.county = placemark.subAdministrativeArea
        self.city = placemark.locality
        self.streetAddress = placemark.thoroughfare
        self.streetNumber = placemark.subThoroughfare
        self.region = placemark.region
        self.timezone = placemark.timeZone
        self.coordinates = placemark.location?.coordinate

        self.addressDictionary = placemark.addressDictionary
        if #available(iOS 11.0, *) {
            self.postalAddress = placemark.postalAddress
            if let postalAddress = placemark.postalAddress {
                self.formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
            }
        } else {
            self.formattedAddress = placemark.makeAddressString()
        }
        self.areasOfInterest = placemark.areasOfInterest
    }
    
    // MARK: - Private Helper Methods -
 
    fileprivate static func clPlacemarkFromPlace(_ place: Place) -> CLPlacemark? {
        guard let coordinates = place.coordinates else {
            return nil
        }
        
        let dict: [String:String?] = [
            CLPlacemarkDictionaryKey.kAdministrativeArea: place.state,
            CLPlacemarkDictionaryKey.kSubAdministrativeArea: place.county,
            CLPlacemarkDictionaryKey.kSubLocality: place.county,
            CLPlacemarkDictionaryKey.kState: place.state,
            CLPlacemarkDictionaryKey.kStreet: place.streetAddress,
            CLPlacemarkDictionaryKey.kSubThoroughfare: place.streetNumber,
            CLPlacemarkDictionaryKey.kPostCodeExtension: "",
            CLPlacemarkDictionaryKey.kCity: place.city,
            CLPlacemarkDictionaryKey.kZIP: place.postalCode,
            CLPlacemarkDictionaryKey.kCountry: place.country,
            CLPlacemarkDictionaryKey.kCountryCode: place.isoCountryCode
        ]
        
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: dict.compactMapValues({$0}))
        return (placemark as CLPlacemark)
    }
    
    fileprivate static func cnPostalAddressFromPlace(_ place: Place) -> CNPostalAddress {
        let cn = CNMutablePostalAddress()
        cn.state = place.state ?? ""
        cn.city = place.city ?? ""
        cn.street = place.streetAddress ?? ""
        cn.postalCode = place.postalCode ?? ""
        cn.country = place.country ?? ""
        cn.isoCountryCode = place.isoCountryCode ?? ""
        if #available(iOS 10.3, *) {
            cn.subAdministrativeArea = place.county ?? ""
            cn.subLocality = place.city ?? ""
        }
        return cn
    }

    
}
