//
//  Autocomplete+Here.swift
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
    
    class Here: JSONNetworkHelper, AutocompleteProtocol {
        
        // MARK: - Public Properties
        
        /// Type of autocomplete operation
        public var operation: AutocompleteOp
        
        /// Timeout interval for request.
        public var timeout: TimeInterval? = 5
        
        /// API Key
        /// See https://developers.google.com/places/web-service/get-api-key.
        public var APIKey: String
        
        /// Search within a geographic area. This is a hard filter. Results will be returned if they are located within the specified area.
        ///
        /// NOTE: Value is not applicable for `.addressDetail`
        public var proximityArea: ProximityArea?
        
        /// Maximum number of results to be returned.
        ///
        /// NOTE: Value is not applicable for `.addressDetail`
        public var limit: Int?
        
        /// Select the language to be used for result rendering from a list of BCP47 compliant Language Codes.
        public var locale: String?
        
        /// Callback to call at the end of the operation.
        private var callback: ((Result<[Autocomplete.Data], LocationError>) -> Void)?
        
        /// Description
        public var description: String {
            return JSONStringify([
                "apiKey": APIKey.trunc(length: 5),
                "limitResults": limit?.description,
                "locale": locale,
                "area": proximityArea
            ])
        }
        
        // MARK: - Initialization
        
        /// Search for matches of a partial search address.
        /// Returned values is an array of `Autocomplete.AutocompleteResult.partial`.
        ///
        /// - Parameters:
        ///   - partialAddress:  partial match of the address.
        ///   - APIKey: API Key.
        ///   - proximityArea: contextual area options.
        public init(partialMatches partialAddress: String, APIKey: String = SharedCredentials[.google],
                    proximityArea: ProximityArea? = nil) {
            self.operation = .partialMatch(partialAddress)
            self.proximityArea = proximityArea
            self.APIKey = APIKey
            
            super.init()
        }
        
        /// If you want to get details of a full address, typically returned from partial match search.
        ///
        /// - Parameters:
        ///   - fullAddress: full address.
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
        
        /// If you want to get details of a place identified by an HERE id.
        ///
        /// - Parameters:
        ///   - lookupByID: identifier of the place.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(lookupByID hereID: String, APIKey: String = SharedCredentials[.google]) {
            self.operation = .addressDetail(":ID:\(hereID)")
            self.APIKey = APIKey
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocationError>) -> Void)) {
            do {
                
                self.callback = completion
                let request = try buildRequest()
                
                switch operation {
                case .partialMatch:     executePartialAddressSearch(request)
                case .addressDetail:    executeAddressDetails(request)
                }
            } catch {
                completion(.failure(LocationError.internalError))
            }
        }
        
        // MARK: - Private Function
        
        private func executePartialAddressSearch(_ request: URLRequest) {
            executeDataRequest(request: request, validateResponse: nil) { [weak self] result in
                guard let self = self else { return }
                
                do {
                    guard !self.APIKey.isEmpty else {
                        throw LocationError.invalidAPIKey
                    }
                    
                    switch result {
                    case .failure(let error):
                        self.callback?(.failure(error))
                    case .success(let data):
                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                            self.callback?(.failure(.parsingError))
                            return
                        }
                        
                        let message: String? = json.valueForKeyPath(keyPath: "message") ?? json.valueForKeyPath(keyPath: "error_description")
                        if (message?.isEmpty ?? true) == false {
                            self.callback?(.failure(.other(message!)))
                            return
                        }
                        
                        let places = PartialAddressMatch.fromHereList( json.valueForKeyPath(keyPath: "items") )
                        self.callback?(.success(places))
                    }
                } catch {
                    self.callback?(.failure(error as? LocationError ?? .generic(error)))
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
                        let rawJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        guard let json = rawJSON as? [String: Any] else {
                            self.callback?(.failure(.parsingError))
                            return
                        }
                        
                        // Error catching
                        let message: String? = json.valueForKeyPath(keyPath: "message") ?? json.valueForKeyPath(keyPath: "error_description")
                        if (message?.isEmpty ?? true) == false {
                            self.callback?(.failure(.other(message!)))
                            return
                        }
                        
                        if let list: [[String: Any]] = json.valueForKeyPath(keyPath: "items") {
                            // multiple results (coming from geocode)
                            let places = GeoLocation.fromHereList(list).map({ Autocomplete.Data.place($0) })
                            self.callback?(.success(places))
                            
                        } else if let place = GeoLocation(hereJSON: json).map({ Autocomplete.Data.place($0) }) { // single result
                            self.callback?(.success([place]))
                        }
                    } catch {
                        self.callback?(.failure(.other(error.localizedDescription)))
                    }
                }
            }
        }
        
        private func requestURL() -> URL {
            switch operation {
            case .partialMatch:
                return URL(string: "https://autosuggest.search.hereapi.com/v1/autosuggest")!
                
            case .addressDetail(let address):
                if address.starts(with: ":ID:") {
                    return URL(string: "https://lookup.search.hereapi.com/v1/lookup")!
                } else {
                    return URL(string: "https://geocode.search.hereapi.com/v1/geocode")!
                }
            }
        }
        
        private func buildRequest() throws -> URLRequest {
            // Options
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "apiKey", value: APIKey))
            
            if let limit = proximityArea { // at/in are mutually exclusive
                if case .coordinates = limit {
                    queryItems.appendIfNotNil(URLQueryItem(name: "at", optional: proximityArea?.serverValue))
                } else {
                    queryItems.appendIfNotNil(URLQueryItem(name: "in", optional: proximityArea?.serverValue))
                }
            }
            queryItems.appendIfNotNil(URLQueryItem(name: "limit", optional: (limit != nil ? String(limit!) : nil)))
            queryItems.appendIfNotNil(URLQueryItem(name: "lang", optional: locale))
            
            switch operation {
            case .partialMatch(let partialAddress):
                queryItems.append(URLQueryItem(name: "q", value: partialAddress))
            case .addressDetail(let address):
                if address.starts(with: ":ID:") {
                    queryItems.append(URLQueryItem(name: "id", value: address.replacingOccurrences(of: ":ID:", with: "")))
                } else {
                    queryItems.append(URLQueryItem(name: "q", value: address))
                }
            }
            
            // Generate url
            var urlComponents = URLComponents(url: requestURL(), resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout ?? TimeInterval.highInterval)
            print(request)
            return request
        }
        
    }
    
}

// MARK: - Autocomplete.Here Structures

public extension Autocomplete.Here {
    
    /// Search within a geographic area. This is a hard filter. Results will be returned if they are located within the specified area.
    /// - `countryCodes`: a country (or multiple countries), provided as comma-separated ISO 3166-1 alpha-3 country codes.
    /// - `circle`: a circular area, provided as latitude, longitude, and radius (in meters).
    /// - `boundingBox`: a bounding box, provided as west longitude, south latitude, east longitude, north latitude.
    /// - `proximity`:
    enum ProximityArea: CustomStringConvertible {
        case countryCodes([String])
        case circle(CLCircularRegion)
        case boundingBox(BoundingBox)
        case coordinates(CLLocationCoordinate2D)
        
        internal var serverValue: String {
            switch self {
            case .countryCodes(let codes): // countryCode:CAN,MEX,USA
                return "countryCode:\(codes.map({ $0.uppercased() }).joined(separator:","))"
                
            case .circle(let circle): // circle:52.53,13.38;r=10000
                return "circle:\(circle.center.latitude),\(circle.center.longitude);r=\(circle.radius)"
                
            case .boundingBox(let bbox):
                return bbox.serverValue
                
            case .coordinates(let coordinates):
                return coordinates.commaLngLat
                
            }
        }
        
        // MARK: - Private Properties
        
        private var kind: Int {
            switch self {
            case .countryCodes: return 0
            case .circle:       return 1
            case .boundingBox:  return 2
            case .coordinates:    return 3
            }
        }
        
        public var description: String {
            switch self {
            case .countryCodes(let c):  return "Countries=\(c.joined(separator: ","))"
            case .circle(let c):        return "Circle=\(c.description)"
            case .boundingBox(let b):   return "BBox=\(b.description)"
            case .coordinates(let c):   return "Coords=\(c.description)"
            }
        }
        
    }
    
    struct BoundingBox: CustomStringConvertible {
        let westLong: CLLocationDegrees
        let southLat: CLLocationDegrees
        let eastLong: CLLocationDegrees
        let northLat: CLLocationDegrees
        
        public init(wLng: CLLocationDegrees, sLat: CLLocationDegrees,
                    eLng: CLLocationDegrees, nLat: CLLocationDegrees) {
            self.westLong = wLng
            self.southLat = sLat
            self.eastLong = eLng
            self.northLat = nLat
        }
        
        internal var serverValue: String {
            // format: bbox:{west longitude},{south latitude},{east longitude},{north latitude}
            // Example: bbox:13.08836,52.33812,13.761,52.6755
            "bbox:\(westLong),\(southLat),\(eastLong),\(northLat)"
        }
        
        public var description: String {
            "\(westLong),\(southLat),\(eastLong),\(northLat)"
        }
        
    }
    
}

// MARK: - CLLocationCoordinate2D

fileprivate extension CLLocationCoordinate2D {
    
    var hereWSParameter: String {
        return "\(latitude),\(longitude)"
    }
    
}
