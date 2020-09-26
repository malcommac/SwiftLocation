//
//  File.swift
//  
//
//  Created by daniele on 26/09/2020.
//

import Foundation
import CoreLocation

public struct IPLocation: Decodable, CustomStringConvertible {
    
    public enum Keys {
        case hostname
        case continent
        case continentCode
        case country
        case countryCode
        case region
        case regionCode
        case city
        case postalCode
    }
    
    public let coordinates: CLLocationCoordinate2D
    public private(set) var info = [Keys: String?]()
    public let ip: String

    public init(from decoder: Decoder) throws {
        guard let decoderService = decoder.userInfo[IPServiceDecoder] as? IPServiceDecoders else {
            throw LocatorErrors.parsingError
        }
        
        switch decoderService {
        case .ipstack:
            let container = try decoder.container(keyedBy: IPStackCodingKeys.self)
            
            self.ip = try container.decode(String.self, forKey: .ip)
            
            let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
            let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
            self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            self.info[Keys.hostname] = try container.decodeIfPresent(String.self, forKey: .hostname)
            
            self.info[Keys.continent] = try container.decodeIfPresent(String.self, forKey: .continent)
            self.info[Keys.continentCode] = try container.decodeIfPresent(String.self, forKey: .continentCode)
            
            self.info[Keys.country] = try container.decodeIfPresent(String.self, forKey: .country)
            self.info[Keys.countryCode] = try container.decodeIfPresent(String.self, forKey: .countryCode)
            
            self.info[Keys.region] = try container.decodeIfPresent(String.self, forKey: .region)
            self.info[Keys.regionCode] = try container.decodeIfPresent(String.self, forKey: .regionCode)
            
        case .ipdata:
            let container = try decoder.container(keyedBy: IPDataCodingKeys.self)

            self.ip = try container.decode(String.self, forKey: .ip)
         
            let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
            let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
            self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            self.info[Keys.continent] = try container.decodeIfPresent(String.self, forKey: .continent)
            self.info[Keys.continentCode] = try container.decodeIfPresent(String.self, forKey: .continentCode)
            
            self.info[Keys.country] = try container.decodeIfPresent(String.self, forKey: .country)
            self.info[Keys.countryCode] = try container.decodeIfPresent(String.self, forKey: .countryCode)
            
            self.info[Keys.region] = try container.decodeIfPresent(String.self, forKey: .region)
            self.info[Keys.regionCode] = try container.decodeIfPresent(String.self, forKey: .regionCode)
            
            self.info[Keys.city] = try container.decodeIfPresent(String.self, forKey: .city)
            self.info[Keys.postalCode] = try container.decodeIfPresent(String.self, forKey: .postalCode)
        }
    }
    
    // MARK: - IPData
    
    private enum IPDataCodingKeys: String, CodingKey {
        case ip,
             city,
             latitude, longitude,
             postalCode = "postal",
             continent = "continent_name", continentCode = "continent_code",
             country = "country_name", countryCode = "country_code",
             region = "region", regionCode = "region_code"
    }
        
    // MARK: - IPStack
    
    private enum IPStackCodingKeys: String, CodingKey {
        case latitude,
             longitude,
             hostname,
             ip,
             continent = "continent_name", continentCode = "continent_code",
             country = "country_name", countryCode = "country_code",
             region = "region_name", regionCode = "region_code"
    }
    
    public var description: String {
        return "{lat=\(coordinates.latitude), lng=\(coordinates.longitude), info=\(info)}"
    }
        
}
