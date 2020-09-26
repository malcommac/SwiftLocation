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
        case ip
        case continent
        case country
        case countryCode
        case region
        case regionCode
    }
    
    public let coordinates: CLLocationCoordinate2D
    public let info: [Keys: String]

    public init(from decoder: Decoder) throws {
        guard let decoderService = decoder.userInfo[IPServiceDecoder] as? IPServiceDecoders else {
            throw LocatorErrors.parsingError
        }
        
        switch decoderService {
        case .ipstack:
            let container = try decoder.container(keyedBy: IPStackCodingKeys.self)

            self.info = [
                Keys.hostname: try container.decodeIfPresent(String.self, forKey: .hostname),
                Keys.continent: try container.decodeIfPresent(String.self, forKey: .continent),
                
                Keys.country: try container.decodeIfPresent(String.self, forKey: .country),
                Keys.countryCode: try container.decodeIfPresent(String.self, forKey: .countryCode),
                
                Keys.region: try container.decodeIfPresent(String.self, forKey: .region),
                Keys.regionCode: try container.decodeIfPresent(String.self, forKey: .regionCode),
                Keys.ip: try container.decodeIfPresent(String.self, forKey: .ip),
            ].compactMapValues({ $0 })
            let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
            let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
            self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
        
    private enum IPStackCodingKeys: String, CodingKey {
        case latitude,
             longitude,
             hostname,
             ip,
             continent = "continent_name",
             country = "country_name", countryCode = "country_code",
             region = "region_name", regionCode = "region_code"
    }
    
    public var description: String {
        return "{lat=\(coordinates.latitude), lng=\(coordinates.longitude), info=\(info)}"
    }
        
}
