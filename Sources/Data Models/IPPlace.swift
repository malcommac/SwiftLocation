//
//  IPPlace.swift
//  SwiftLocation
//
//  Created by dan on 19/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class IPPlace {
    
    /// City. Example: `"Mountain View"`
    public let city: String?
    
    /// Country code short. Example: `"US"`
    public let countryCode: String?
    
    /// Country name. Example: `"United States"`
    public let countryName: String?
    
    /// IP used for the query. Example: `"173.194.67.94"`
    public var ip: String?
   
    /// Internet Service Provider name. Example: `"Google"`
    public var isp: String?
    
    /// IP Coordinates.
    public var coordinates: CLLocationCoordinate2D?
    
    /// Organization name. Example: `"Google"`
    public var organization: String?
    
    /// Region/State code short. Example: `"CA"` or `"10"`
    public var regionCode: String?
    
    /// Region/State name. Example: `"California"`
    public var regionName: String?
    
    /// Timezone. Example: `"America/Los_Angeles"`
    public var timezone: String?
    
    /// Zip code. Example: `"94043"`
    public var zipCode: String?

    // MARK: - Initialization -
    
    internal init(ipAPIJSON json: Any) {
        self.countryName = valueAtKeyPath(root: json, ["country"])
        self.countryCode = valueAtKeyPath(root: json, ["countryCode"])
        self.regionName = valueAtKeyPath(root: json, ["regionName"])
        self.regionCode = valueAtKeyPath(root: json, ["region"])
        self.city = valueAtKeyPath(root: json, ["city"])
        self.zipCode = valueAtKeyPath(root: json, ["zip"])
       
        if let lat: Double = valueAtKeyPath(root: json, ["lat"]),
            let lng: Double = valueAtKeyPath(root: json, ["lon"]) {
            self.coordinates = CLLocationCoordinate2DMake(lat, lng)
        }
        
        self.timezone = valueAtKeyPath(root: json, ["timezone"])
        self.isp = valueAtKeyPath(root: json, ["isp"])
        self.organization = valueAtKeyPath(root: json, ["org"])
    }
    
    internal init(ipAPICoJSON json: Any) {
        self.ip = valueAtKeyPath(root: json, ["ip"])
        self.countryName = valueAtKeyPath(root: json, ["country_name"])
        self.countryCode = valueAtKeyPath(root: json, ["country"])
        self.regionName = valueAtKeyPath(root: json, ["region"])
        self.regionCode = valueAtKeyPath(root: json, ["region_code"])
        self.city = valueAtKeyPath(root: json, ["city"])
        self.zipCode = valueAtKeyPath(root: json, ["postal"])
        
        if let lat: Double = valueAtKeyPath(root: json, ["latitude"]),
            let lng: Double = valueAtKeyPath(root: json, ["longitude"]) {
            self.coordinates = CLLocationCoordinate2DMake(lat, lng)
        }
        
        self.timezone = valueAtKeyPath(root: json, ["timezone"])
        self.isp = valueAtKeyPath(root: json, ["org"])
        self.organization = valueAtKeyPath(root: json, ["org"])
    }
    
}
