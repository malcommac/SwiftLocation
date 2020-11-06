//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation
import CoreLocation

public extension Geocoder {
    
    class Google: JSONNetworkHelper, GeocoderServiceProtocol {

        /// Operation to perform
        public private(set) var operation: GeocoderOperation
        
        /// Service API Key (https://console.cloud.google.com/google/maps-apis/credentials)
        public var APIKey: String
        
        /// Request timeout.
        public var timeout: TimeInterval = 5
        
        /// The language in which to return results.
        /// See https://developers.google.com/maps/faq#languagesupport for more informations.
        /// NOTE: If language is not supplied, the geocoder attempts to use the preferred language as specified in the Accept-Language header, or the native language of the domain from which the request is sent.
        /// More info: https://developers.google.com/maps/documentation/geocoding/overview
        public var language: String?
        
        /// The region code, specified as a ccTLD ("top-level domain") two-character value.
        /// This parameter will only influence, not fully restrict, results from the geocoder.
        /// For more informations see https://developers.google.com/maps/documentation/geocoding/overview#RegionCodes.
        public var region: String?
        
        /// The bounding box of the viewport within which to bias geocode results more prominently.
        /// This parameter will only influence, not fully restrict, results from the geocoder.
        /// See https://developers.google.com/maps/documentation/geocoding/overview#Viewports for more infos.
        public var bounds: Viewport?
        
        /// A components filter with elements separated by a pipe (|).
        /// The components filter is required if the request doesn't include an address.
        /// Each element in the components filter consists of a component:value pair, and fully restricts the results from the geocoder.
        /// See https://developers.google.com/maps/documentation/geocoding/overview#component-filtering for more infos.
        public var components: [String]?
        
        /// A filter of one or more location types.
        /// By default is set to `nil`.
        public var locationTypes: [LocationTypes]?
        
        public var description: String {
            JSONStringify([
                "APIKey": APIKey.trunc(length: 5),
                "timeout": timeout,
                "language": language ?? "",
                "region": region ?? "",
                "bounds": bounds?.description ?? "",
                "components": components ?? "",
                "locationTypes": locationTypes?.description ?? ""
            ])
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode coordinates to return estimated address.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - APIKey: API key
        public init(coordinates: CLLocationCoordinate2D, APIKey: String) {
            self.operation = .geoAddress(coordinates)
            self.APIKey = APIKey
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String, APIKey: String) {
            self.operation = .getCoordinates(address)
            self.APIKey = APIKey
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocatorErrors>) -> Void)) {
            do {
                let request = try buildRequest()
                executeDataRequest(request: request) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let rawData):
                        do {
                            let locations = try Geocoder.Google.parseRawData(rawData)
                            completion(.success(locations))
                        } catch {
                            completion(.failure(.parsingError))
                        }
                    }
                }
            } catch {
                completion(.failure(.generic(error)))
            }
        }
        
        // MARK: - Private Functions
        
        private func buildRequest() throws -> URLRequest {
            var url: URL!
            var queryItems = [ URLQueryItem(name: "key", value: APIKey), ]
            
            switch operation {
            case .getCoordinates(let address):
                url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
                queryItems.append(URLQueryItem(name: "address", value: address))
                
            case .geoAddress(let coordinates):
                url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
                queryItems.append(URLQueryItem(name: "latlng", value: "\(coordinates.latitude),\(coordinates.longitude)"))
            }
            
            // Options
            queryItems.appendIfNotNil(URLQueryItem(name: "language", optional: language))
            queryItems.appendIfNotNil(URLQueryItem(name: "bounds", optional: bounds?.rawValue))
            queryItems.appendIfNotNil(URLQueryItem(name: "region", optional: region))
            queryItems.appendIfNotNil(URLQueryItem(name: "components", optional: components?.joined(separator: "|")))
            queryItems.appendIfNotNil(URLQueryItem(name: "location_type", optional: locationTypes?.map({ $0.rawValue }).joined(separator: "|")))
            
            // Create
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            
            guard let fullURL = urlComponents?.url else {
                throw LocatorErrors.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            return request
        }
        
        internal static func parseRawData(_ data: Data) throws -> [GeoLocation] {
            return try GeoLocation.fromGoogleList(data)
        }
        
    }
    
}

// MARK: - GoogleGeocoderService Extension

public extension Geocoder.Google {
    
    /// The bounds parameter defines the latitude/longitude coordinates of the southwest and northeast corners.
    struct Viewport: Codable, CustomStringConvertible {
        var southwest: CLLocationCoordinate2D
        var northeast: CLLocationCoordinate2D
        
        fileprivate var rawValue: String {
            "\(southwest.latitude),\(southwest.longitude)|\(northeast.latitude),\(northeast.longitude)"
        }
        
        public var description: String {
            rawValue
        }
        
    }
    
    /// A filter of one or more location types, separated by a pipe (|). If the parameter contains multiple location types, the API returns all addresses that match any of the types
    /// - `rooftop`: returns only the addresses for which Google has location information accurate down to street address precision.
    /// - `rangeInterpolated`: returns only the addresses that reflect an approximation (usually on a road) interpolated between two precise points (such as intersections).
    ///                       An interpolated range generally indicates that rooftop geocodes are unavailable for a street address.
    /// - `geometricCenter`: returns only geometric centers of a location such as a polyline (for example, a street) or polygon (region).
    /// - `approximate`: returns only the addresses that are characterized as approximate.
    enum LocationTypes: String, Codable {
        case rooftop = "ROOFTOP"
        case rangeInterpolated = "RANGE_INTERPOLATED"
        case geometricCenter = "GEOMETRIC_CENTER"
        case approximate = "APPROXIMATE"
    }
    
}
