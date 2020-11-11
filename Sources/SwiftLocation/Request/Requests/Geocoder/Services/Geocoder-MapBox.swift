//
//  Geocoder+MapBox.swift
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

public extension Geocoder {
    
    /// Geocoding using MapBox
    /// https://docs.mapbox.com/api/search/#geocoding
    class MapBox: JSONNetworkHelper, GeocoderServiceProtocol {
        
        /// Operation to perform.
        /// NOTE: Usually it's set via init and you should not change it.
        public var operation: GeocoderOperation
        
        /// API Key for service.
        /// https://account.mapbox.com
        public var APIKey: String
        
        /// Request timeout.
        public var timeout: TimeInterval?
        
        /// Specify the user’s language. This parameter controls the language of the text supplied in responses.
        /// See https://docs.mapbox.com/api/search/#language-coverage for more info.
        public var locale: String?
        
        /// Limit results to one or more countries. Permitted values are ISO 3166 alpha 2 country codes separated by commas.
        /// See https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for more info.
        public var countryCode: String?
        
        /// Specify the maximum number of results to return.
        /// The default is 1 and the maximum supported is 5.
        ///
        /// NOTE: Limit must be combined with a single type parameter when reverse geocoding.
        public var limit: Int?
        
        /// Specify whether to request additional metadata about the recommended navigation destination corresponding to the feature (true) or not (false, default).
        /// Only applicable for address features.
        public var includeRoutingData: Bool?
        
        /// Filter results to include only a subset (one or more) of the available feature types.
        /// By default is `nil`.
        public var resultTypes: [ResultTypes]?
        
        // MARK: - Reverse Geocoder Specific Properties
        
        /// Decides how results are sorted in a reverse geocoding query if multiple results are requested using a limit other than 1.
        /// Options are distance (default), which causes the closest feature to always be returned first, and score,
        /// which allows high-prominence features to be sorted higher than nearer, lower-prominence features.
        ///
        /// NOTE: Applicable only for reverse geocoder.
        public var reverseMode: ReverseMode?
        
        // MARK: - Forward Geocoder Specific Properties
        
        /// Bias the response to favor results that are closer to this location.
        ///
        /// NOTE: Applicable only for geocoder.
        public var proximityRegion: CLLocationCoordinate2D?
        
        /// Limit results to only those contained within the supplied bounding box.
        /// Bounding boxes should be supplied as four numbers separated by commas, in minLon,minLat,maxLon,maxLat order.
        /// The bounding box cannot cross the 180th meridian.
        /// By default is `nil`.
        ///
        /// NOTE: Applicable only for geocoder.
        public var boundingBox: BoundingBox?
        
        /// Specify whether the Geocoding API should attempt approximate, as well as exact,
        /// matching when performing searches (true, default), or whether it should opt out of this
        /// behavior and only attempt exact matching (false).
        /// For example, the default setting might return Washington, DC for a query of wahsington, even though the query was misspelled.
        ///
        /// NOTE: Applicable only for geocoder.
        public var useFuzzyMatch: Bool?
        
        /// Description.
        public var description: String {
            let data: [String: Any] = [
                "APIKey": APIKey.trunc(length: 5),
                "timeout": timeout ?? "",
                "locale": locale ?? "",
                "country": countryCode ?? "",
                "limit": limit ?? 0,
                "routing": includeRoutingData ?? "",
                "types": resultTypes?.description ?? "",
                "reverseMode": reverseMode?.description ?? "",
                "proximityRegion": proximityRegion?.description ?? "",
                "boundingBox": boundingBox?.description ?? "",
                "fuzzyMatch": useFuzzyMatch ?? ""
            ]
            return JSONStringify(data)
        }
        
        // MARK: - Initialize
        
        /// Initialize to reverse geocode coordinates to return estimated address.
        ///
        /// - Parameters:
        ///   - coordinates: coordinates.
        ///   - APIKey: API key
        public init(coordinates: CLLocationCoordinate2D, APIKey: String = SharedCredentials[.mapBox]) {
            self.operation = .geoAddress(coordinates)
            self.APIKey = APIKey
        }
        
        /// Initialize to reverse geocode a pair of coordinates.
        /// - Parameters:
        ///   - lat: latitude.
        ///   - lng: longitude.
        ///   - APIKey: API Key.
        public convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees, APIKey: String = SharedCredentials[.mapBox]) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.init(coordinates: coordinates, APIKey: APIKey)
        }
        
        /// Initialize to geocode given address and obtain coordinates.
        ///
        /// - Parameters:
        ///   - address: address to geocode.
        ///   - APIKey: API Key
        public init(address: String, APIKey: String = SharedCredentials[.mapBox]) {
            self.operation = .getCoordinates(address)
            self.APIKey = APIKey
        }
        
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[GeoLocation], LocationError>) -> Void)) {
            do {
                guard !APIKey.isEmpty else {
                    throw LocationError.invalidAPIKey
                }
                
                let request = try buildRequest()
                executeDataRequest(request: request) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let rawData):
                        do {
                            let rawJSON = try JSONSerialization.jsonObject(with: rawData, options: .allowFragments)
                            guard let json = rawJSON as? [String: Any] else {
                                completion(.failure(.parsingError))
                                return
                            }
                            
                            let message: String? = json.valueForKeyPath(keyPath: "message")
                            if (message?.isEmpty ?? true) == false {
                                completion(.failure(.other(message!)))
                                return
                            }
                            
                            let locations = GeoLocation.fromMapBoxList(json.valueForKeyPath(keyPath: "features"))
                            completion(.success(locations))
                        } catch {
                            completion(.failure(.parsingError))
                        }
                    }
                }
            } catch {
                completion(.failure(error as? LocationError ?? .generic(error)))
            }
        }
        
        private func buildRequest() throws -> URLRequest {
            var url: URL!
            var queryItems = [
                URLQueryItem(name: "format", value: "jsonv2")
            ]
            
            // Options
            queryItems.append(URLQueryItem(name: "access_token", value: APIKey))
            queryItems.appendIfNotNil(URLQueryItem(name: "country", optional: countryCode))
            queryItems.appendIfNotNil(URLQueryItem(name: "language", optional: locale))
            queryItems.appendIfNotNil(URLQueryItem(name: "limit", optional: (limit != nil ? String(limit!) : nil)))
            queryItems.appendIfNotNil(URLQueryItem(name: "routing", optional: includeRoutingData?.serverValue))
            queryItems.appendIfNotNil(URLQueryItem(name: "types", optional: resultTypes?.map({ $0.rawValue }).joined(separator: ",")))
            
            switch operation {
            case .getCoordinates(let address):
                queryItems.append(URLQueryItem(name: "autocomplete", value: "true"))
                queryItems.appendIfNotNil(URLQueryItem(name: "bbox", optional: boundingBox?.rawValue))
                queryItems.appendIfNotNil(URLQueryItem(name: "fuzzyMatch", optional: useFuzzyMatch?.serverValue))
                queryItems.appendIfNotNil(URLQueryItem(name: "proximity", optional: proximityRegion?.commaLngLat))
                
                url = URL(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(address.urlEncoded).json")!
                
            case .geoAddress(let coordinates):
                url = URL(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(coordinates.longitude),\(coordinates.latitude).json")!
                queryItems.appendIfNotNil(URLQueryItem(name: "reverseMode", optional: reverseMode?.rawValue))
                
            }
            
            // Create
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout ?? TimeInterval.highInterval)
            return request
        }
        
        private static func parseRawData(_ data: Data) throws -> [GeoLocation] {
            return try GeoLocation.fromOpenStreetList(data)
        }
        
    }
    
}

public extension Geocoder.MapBox {
    
    /// Decides how results are sorted in a reverse geocoding query if multiple results are requested using a limit other than 1
    enum ReverseMode: String, CustomStringConvertible {
        case distance
        case score
        
        public var description: String {
            rawValue
        }
    }
    
    /// A bounding box array in the form
    struct BoundingBox: CustomStringConvertible {
        public let minLon: CLLocationDegrees
        public let minLat: CLLocationDegrees
        
        public let maxLon: CLLocationDegrees
        public let maxLat: CLLocationDegrees
        
        internal var rawValue: String {
            "\(minLon),\(minLat),\(maxLon),\(maxLat)"
        }
        
        public var description: String {
            rawValue
        }
        
        public init(minLat: CLLocationDegrees, minLon: CLLocationDegrees,
                    maxLat: CLLocationDegrees, maxLon: CLLocationDegrees) {
            self.minLat = minLat
            self.minLon = minLon
            self.maxLat = maxLat
            self.maxLon = maxLon
        }
        
    }
    
    /// Filter results to include only a subset (one or more) of the available feature types.
    enum ResultTypes: String, CustomStringConvertible {
        case country,
             region,
             postcode,
             district,
             place,
             locality,
             neighborhood,
             address,
             poi
        
        public static let all: [ResultTypes] = [.country, .region, .postcode, .district, .place, .locality, .neighborhood, .address, .poi]
        
        public var description: String {
            rawValue
        }
    }
    
}
