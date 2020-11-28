//
//  Autocomplete+Google.swift
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

public extension Autocomplete {
    
    class Google: JSONNetworkHelper, AutocompleteProtocol {
        
        // MARK: - Public Properties
        
        /// Type of autocomplete operation
        public var operation: AutocompleteOp
        
        /// Timeout interval for request.
        public var timeout: TimeInterval? = 5
        
        /// API Key
        /// See https://developers.google.com/places/web-service/get-api-key.
        public var APIKey: String
        
        /// This will send `X-Ios-Bundle-Identifier` header to the request.
        /// You can set it directly from the credentials store as `.googleBundleRestrictionID`.
        /// NOTE: If you enable app-restrictions in the api-console, these headers must be sent.
        public var bundleRestrictionID: String? = SwiftLocation.credentials[.googleBundleRestrictionID]
        
        /// Restrict results to be of certain type, `nil` to ignore this filter.
        public var placeTypes: Set<PlaceTypes>? = nil
        
        /// The distance (in meters) within which to return place results.
        /// Note that setting a radius biases results to the indicated area,
        /// but may not fully restrict results to the specified area.
        /// More info: https://developers.google.com/places/web-service/autocomplete#location_biasing
        /// and https://developers.google.com/places/web-service/autocomplete#location_restrict.
        public var radius: Float? = nil
        
        /// The point around which you wish to retrieve place information
        public var location: CLLocationCoordinate2D?
        
        /// Returns only those places that are strictly within the region defined by location and radius.
        /// This is a restriction, rather than a bias, meaning that results outside this region will
        /// not be returned even if they match the user input.
        public var strictBounds: Bool = false
        
        /// The language code, indicating in which language the results should be returned, if possible.
        public var locale: String?
        
        /// A grouping of places to which you would like to restrict your results up to 5 countries.
        /// Countries must be added in ISO3166-1_alpha-2 version you can found:
        /// https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2.
        public var countries: Set<String>?
        
        /// Description
        public var description: String {
            return JSONStringify([
                "apiKey": APIKey.trunc(length: 5),
                "timeout": timeout,
                "placeTypes": placeTypes,
                "radius": radius,
                "location": location,
                "strictBounds": strictBounds,
                "locale": locale,
                "countries": countries
            ])
        }
        
        // MARK: - Private Properties
        
        /// Partial searcher.
        private var partialQuerySearcher: MKLocalSearchCompleter?
        private var fullQuerySearcher: MKLocalSearch?
        
        /// Callback to call at the end of the operation.
        private var callback: ((Result<[Autocomplete.Data], LocationError>) -> Void)?
        
        // MARK: - Initialization
        
        /// Search for matches of a partial search address.
        /// Returned values is an array of `Autocomplete.AutocompleteResult.partial`.
        ///
        /// - Parameters:
        ///   - partialMatch: partial match of the address.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(partialMatches partialAddress: String, APIKey: String = SharedCredentials[.google]) {
            self.operation = .partialMatch(partialAddress)
            self.APIKey = APIKey
            
            super.init()
        }
        
        /// You can use this method when you have a full address and you want to get the details.
        ///
        /// - Parameter addressDetail: full address
        
        /// If you want to get the details of a partial search result obtained from `init(partialMatches:region)` call, you
        /// can use this method passing the full address.
        /// You can also pass the `id` of `PartialAddressMatch` to get more info about a partial matched result.
        ///
        /// - Parameters:
        ///   - fullAddress: full address to search
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(detailsFor fullAddress: String, APIKey: String = SharedCredentials[.google]) {
            self.operation = .addressDetail(fullAddress)
            self.APIKey = APIKey
            
            super.init()
        }
        
        /// Initialize with request to get details for given result item.
        /// - Parameters:
        ///   - resultItem: result item, PartialAddressMatch.
        ///   - APIKey: API Key.
        public init?(detailsFor resultItem: PartialAddressMatch?, APIKey: String = SharedCredentials[.google]) {
            guard let id = resultItem?.id else {
                return nil
            }
            
            self.operation = .addressDetail(id)
            self.APIKey = APIKey
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocationError>) -> Void)) {
            do {
                guard !APIKey.isEmpty else {
                    throw LocationError.invalidAPIKey
                }
                
                self.callback = completion
                let request = try buildRequest()
                
                switch operation {
                case .partialMatch:     executePartialAddressSearch(request)
                case .addressDetail:    executeAddressDetails(request)
                }
            } catch {
                completion(.failure(error as? LocationError ?? LocationError.internalError))
            }
        }
        
        // MARK: - Private Function
        
        private func executePartialAddressSearch(_ request: URLRequest) {
            executeDataRequest(request: request, validateResponse: nil) { [weak self] result in
                guard let self = self else { return }
                
                do {
                    switch result {
                    case .failure(let error):
                        self.callback?(.failure(error))
                    case .success(let data):
                        guard let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                            self.callback?(.failure(.parsingError))
                            return
                        }
                        
                        // Custom error message returned from call.
                        let errorMessage: String? = jsonData.valueForKeyPath(keyPath: "error_message")
                        if (errorMessage?.isEmpty ?? true) == false {
                            self.callback?(.failure(.other(errorMessage!)))
                        }
                        
                        let places = PartialAddressMatch.fromGoogleList( jsonData.valueForKeyPath(keyPath: "predictions") )
                        self.callback?(.success(places))
                    }
                } catch {
                    self.callback?(.failure(.generic(error)))
                }
            }
        }
        
        private func executeAddressDetails(_ request: URLRequest) {
            executeDataRequest(request: request, validateResponse: nil) { result in
                switch result {
                case .failure(let error):
                    self.callback?(.failure(error))
                case .success(let data):
                    do {
                        guard let detailPlace = try GeoLocation.fromGoogleSingle(data) else {
                            self.callback?(.failure(.notFound))
                            return
                        }
                        
                        self.callback?(.success([.place(detailPlace)]))
                    } catch {
                        self.callback?(.failure(.other(error.localizedDescription)))
                    }
                }
            }
        }
        
        private func requestURL() -> URL {
            switch operation {
            case .partialMatch:
                return URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
                
            case .addressDetail:
                return URL(string: "https://maps.googleapis.com/maps/api/place/details/json")!
            }
        }
        
        private func buildRequest() throws -> URLRequest {
            // Options
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "key", value: APIKey))
            queryItems.appendIfNotNil(URLQueryItem(name: "types", optional: placeTypes?.map { $0.rawValue }.joined(separator: ",")))
            queryItems.appendIfNotNil(URLQueryItem(name: "location", optional: location?.commaLatLng))
            queryItems.appendIfNotNil(URLQueryItem(name: "radius", optional: (radius != nil ? String(radius!) : nil)))

            if strictBounds {
                queryItems.append(URLQueryItem(name: "strictbounds", value: nil))
            }
            
            queryItems.appendIfNotNil(URLQueryItem(name: "language", optional: locale?.lowercased()))
            queryItems.appendIfNotNil(URLQueryItem(name: "components", optional: countries?.map {
                return "country:\($0)"
            }.joined(separator: "|")))
            
            switch operation {
            case .partialMatch(let partialAddress):
                queryItems.append(URLQueryItem(name: "input", value: partialAddress))
            case .addressDetail(let address):
                queryItems.append(URLQueryItem(name: "placeid", value: address))
            }
            
            // Generate url
            var urlComponents = URLComponents(url: requestURL(), resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            var request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout ?? TimeInterval.highInterval)
            request.addValue(bundleRestrictionID ?? "", forHTTPHeaderField: HTTPHeaders.googleBundleRestriction)
            return request
        }
        
    }
    
}

// MARK: - Autocomplete.Google Extensions

public extension Autocomplete.Google {
    
    /// Restrict results from a Place Autocomplete request to be of a certain type.
    /// See: https://developers.google.com/places/web-service/autocomplete#place_types
    ///
    /// - geocode: return only geocoding results, rather than business results.
    /// - address: return only geocoding results with a precise address.
    /// - establishment: return only business results.
    /// - regions: return any result matching the following types: `locality, sublocality, postal_code, country, administrative_area_level_1, administrative_area_level_2`
    /// - cities: return results that match `locality` or `administrative_area_level_3`.
    enum PlaceTypes: String, CustomStringConvertible {
        case geocode
        case address
        case establishment
        case regions
        case cities
        
        public var description: String {
            rawValue
        }
    }
    
}
