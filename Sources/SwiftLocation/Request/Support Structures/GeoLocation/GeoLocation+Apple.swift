//
//  GeoLocation+Apple.swift
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
import MapKit

public extension GeoLocation {
    
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
    internal static func fromAppleList(_ placemarks: [CLPlacemark]?) -> [GeoLocation] {
        return placemarks?.compactMap({ GeoLocation(clPlacemark: $0) }) ?? []
    }
    
    internal static func fromAppleList(_ mapItem: [MKMapItem]?) -> [Autocomplete.Data] {
        return mapItem?.compactMap({
            guard let location = GeoLocation(clPlacemark: $0.placemark) else {
                return nil
            }
            
            return .place(location)
        }) ?? []
    }

}
