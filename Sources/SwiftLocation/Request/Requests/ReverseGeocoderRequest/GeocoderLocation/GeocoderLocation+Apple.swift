//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public extension GeocoderLocation {
    
    /// Initialize from CLPlacemark instance.
    /// - Parameter clPlacemark: placemark.
    internal init?(clPlacemark: CLPlacemark) {
        guard let coordinates = clPlacemark.location?.coordinate else {
            return nil
        }
    
        self.coordinates = coordinates
        self.representedObject = clPlacemark
        self.region = clPlacemark.region
        self.timezone = clPlacemark.timeZone
        
        self.info[.name] = clPlacemark.name
        self.info[.formattedAddress] = clPlacemark.formattedAddress
        self.info[.countryCode] = clPlacemark.isoCountryCode
        self.info[.country] = clPlacemark.country
        self.info[.postalCode] = clPlacemark.postalCode
        self.info[.administrativeArea] = clPlacemark.administrativeArea
        self.info[.subAdministrativeArea] = clPlacemark.subAdministrativeArea
        self.info[.locality] = clPlacemark.locality
        self.info[.subLocality] = clPlacemark.subLocality
        self.info[.throughfare] = clPlacemark.thoroughfare
        self.info[.subThroughfare] = clPlacemark.subThoroughfare
        self.info[.POI] = clPlacemark.areasOfInterest?.joined(separator: "|")
    }
    
    /// Initialize from a response of placemarks.
    /// - Parameter placemarks: placemarks to parse.
    /// - Returns: [GeocoderLocation]
    internal static func fromAppleList(_ placemarks: [CLPlacemark]?) -> [GeocoderLocation] {
        return placemarks?.compactMap({ GeocoderLocation(clPlacemark: $0) }) ?? []
    }

}
