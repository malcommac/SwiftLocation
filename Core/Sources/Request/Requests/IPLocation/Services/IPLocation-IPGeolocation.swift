//
//  IPLocation+IPGeolocation.swift
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
    
    /// This is the implementation of IPGeolocation location search by ip.
    /// https://ipgeolocation.io
    class IPGeolocation: IPServiceProtocol {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipgeolocation
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// This service require API Key.
        /// NOTE: See https://app.ipgeolocation.io.
        public var APIKey: String?
        
        /// Locale identifier.
        /// Not all languages are supported (https://ip-api.com/docs/api:json).
        public var locale: String?
        
        // MARK: - Protocol Specific
        
        /// Service underlying.
        public var task: URLSessionDataTask?
        
        /// Operation was cancelled.
        public var isCancelled = false
        
        /// Timeout interval to execute the call.
        public var timeout: TimeInterval = 5
        
        /// Session URL session.
        public var session = URLSession.shared
        
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
        
        /// Initialize a new https://ip-api.com service with given parameters.
        ///
        /// - Parameters:
        ///   - targetIP: IP to discover; ignore this parameter to get the location of the currently machine.
        ///   - APIKey: API Key for service. Signup at https://app.ipgeolocation.io.
        public init(targetIP: String? = nil, APIKey: String = SharedCredentials[.ipGeolocation]) {
            self.targetIP = targetIP
            self.APIKey = APIKey
        }
        
        public func buildRequest() throws -> URLRequest {
            guard let APIKey = self.APIKey, !APIKey.isEmpty else {
                throw LocationError.invalidAPIKey
            }
            
            let serviceURL = URL(string: "https://api.ipgeolocation.io/ipgeo")!
            var urlComponents = URLComponents(string: serviceURL.absoluteString)
            
            urlComponents?.queryItems = [
                URLQueryItem(name: "apiKey", value: APIKey),
                URLQueryItem(name: "lang", value: locale ?? Locale.current.collatorIdentifier?.lowercased() ?? "en"),
                (targetIP != nil ? URLQueryItem(name: "ip", value: targetIP) : nil)
            ].compactMap({ $0 })
            
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            return URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocationError? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            switch httpResponse.statusCode {
            // If your subscription is paused from use.
            // (1) If the provided API key is not valid.
            // (2) If your account has been disabled or locked by admin because of any illegal activity.
            // (3) If you’re making requests after your subscription trial has been expired.
            // (4) If you’ve exceeded your requests limit.
            // (5) If your subscription is not active.
            //(6) If you’re accessing a paid feature on free subscription.
            // (7) If you’re making a request without authorization with our IP Geolocation API.
            case 400, 401: return .usageLimitReached
            case 404: return .notFound // If the queried IP address or domain name is not found in our database.
            case 423: return .reserved // If the queried IP address is a bogon (reserved) IP address like private, multicast, etc.
            default:
                return .other(String(httpResponse.statusCode))
            }
            
        }
        
    }
    
}
