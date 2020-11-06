//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
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
        public var timeout: TimeInterval = 5
        
        /// API Key
        /// See https://developers.google.com/places/web-service/get-api-key.
        public var APIKey: String
        
        /// Restrict results to be of certain type, `nil` to ignore this filter.
        public var placeTypes: Set<PlaceTypes>? = nil
        
        /// The distance (in meters) within which to return place results.
        /// Note that setting a radius biases results to the indicated area,
        /// but may not fully restrict results to the specified area.
        /// More info: https://developers.google.com/places/web-service/autocomplete#location_biasing
        /// and https://developers.google.com/places/web-service/autocomplete#location_restrict.
        public var radius: Float? = nil
        
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
        private var callback: ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)?
        
        // MARK: - Initialization
        
        /// Search for matches of a partial search address.
        /// Returned values is an array of `Autocomplete.AutocompleteResult.partial`.
        ///
        /// - Parameters:
        ///   - partialMatch: partial match of the address.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(partialMatches partialAddress: String, APIKey: String) {
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
        public init(detailsFor fullAddress: String, APIKey: String) {
            self.operation = .addressDetail(fullAddress)
            self.APIKey = APIKey
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)) {
            do {
                
                self.callback = completion
                let request = try buildRequest()
                
                switch operation {
                case .partialMatch:     executePartialAddressSearch(request)
                case .addressDetail:    executeAddressDetails(request)
                }
            } catch {
                completion(.failure(LocatorErrors.internalError))
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
                    self.callback?(.failure(.other(error.localizedDescription)))
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
                throw LocatorErrors.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
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
    enum PlaceTypes: String {
        case geocode
        case address
        case establishment
        case regions
        case cities
    }
    
}
