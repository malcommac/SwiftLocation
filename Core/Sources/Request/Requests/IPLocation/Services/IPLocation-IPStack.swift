//
//  IPLocation+IPStack.swift
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

public extension IPLocation {
    
    /// This is the implementation of IPStack location search by ip.
    /// https://ipstack.com
    class IPStack: IPServiceProtocol {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipstack
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// Locale identifier.
        /// Not all languages are supported (https://ipstack.com/documentation#language).
        public var locale: String?
        
        /// Hostname lookup.
        /// By default, the ipstack API does not return information about the hostname the given IP address resolves to.
        public var hostnameLookup = false
        
        // MARK: - Protocol Specific
        
        /// Service underlying.
        public var task: URLSessionDataTask?
        
        /// Operation was cancelled.
        public var isCancelled = false
        
        /// Timeout interval to execute the call.
        public var timeout: TimeInterval = 5
        
        /// Session URL session.
        public var session = URLSession.shared
        
        /// API key to use the service.
        public var APIKey: String?
        
        public var description: String {
            JSONStringify([
                "targetIP": targetIP ?? "",
                "APIKey": APIKey?.trunc(length: 5) ?? "",
                "locale": locale ?? "",
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
        /// Initialize a new https://ipstack.com/ service with given parameters.
        ///
        /// - Parameters:
        ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
        ///   - APIKey: APIKey to use service (go to https://ipstack.com/product for more infos).
        public init(targetIP: String? = nil, APIKey: String = SharedCredentials[.ipStack]) {
            self.targetIP = targetIP
            self.APIKey = APIKey
        }
        
        private func serviceURL() -> URL {
            guard let targetIP = targetIP else {
                return URL(string: "http://api.ipstack.com/check")!
            }
            
            return URL(string: "http://api.ipstack.com/\(targetIP)")!
        }
        
        public func buildRequest() throws -> URLRequest {
            guard let APIKey = self.APIKey, !APIKey.isEmpty else {
                throw LocationError.invalidAPIKey
            }
            
            var urlComponents = URLComponents(string: serviceURL().absoluteString)
            urlComponents?.queryItems = [
                URLQueryItem(name: "access_key", value: APIKey),
                URLQueryItem(name: "language", optional: locale?.lowercased()),
                URLQueryItem(name: "hostname", value: (hostnameLookup ? "1": "0")),
                URLQueryItem(name: "output", value: "json")
            ].compactMap({ $0 })
            
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            let request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
            return request
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocationError? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            // see https://ipstack.com/documentation#errors
            switch httpResponse.statusCode {
            case 404:           return .notFound
            case 101, 102, 103: return .invalidAPIKey
            case 104:           return .usageLimitReached
            default:            return .other(String(httpResponse.statusCode))
            }
        }
     
    }
    
}
