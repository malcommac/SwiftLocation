//
//  IPLocation+IPIPify.swift
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
    
    /// This is the implementation of IPify location search by ip.
    /// https://www.ipify.org
    class IPify: IPServiceProtocol {
        
        /// Used to retrive data from json.
        public var jsonServiceDecoder: IPServiceDecoders = .ipify
        
        // MARK: - Configurable Settings
        
        /// Optional target IP to discover; `nil` to use current machine internet address.
        public var targetIP: String?
        
        /// Locale.
        /// NOTE: It's ignored for this service.
        public var locale: String?
        
        /// API Key if used.
        public var APIKey: String?
        
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
                "isCancelled": isCancelled,
                "timeout": timeout,
                "decoder": jsonServiceDecoder.rawValue
            ])
        }
        
        /// Initialize a new https://www.ipify.org service with given parameters.
        ///
        /// - Parameters:
        ///   - IP: IP to discover; ignore this parameter to get the location of the currently machine.
        ///   - APIKey: API key (see https://geo.ipify.org/subscriptions)
        public init(targetIP: String? = nil, APIKey: String = SharedCredentials[.ipify]) {
            self.targetIP = targetIP
            self.APIKey = APIKey
        }
        
        public func buildRequest() throws -> URLRequest {
            guard let APIKey = self.APIKey, !APIKey.isEmpty else {
                throw LocationError.invalidAPIKey
            }
            
            let serviceURL = URL(string: "https://geo.ipify.org/api/v1")!
            var urlComponents = URLComponents(string: serviceURL.absoluteString)
            
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: APIKey),
                (targetIP != nil ? URLQueryItem(name: "ipAddress", value: targetIP!) : nil),
            ].compactMap({ $0 })
            
            if !queryItems.isEmpty {
                urlComponents?.queryItems = queryItems
            }
            
            guard let fullURL = urlComponents?.url else {
                throw LocationError.internalError
            }
            
            return URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        }
        
        public func validateResponse(data: IPLocation.Data, httpResponse: HTTPURLResponse) -> LocationError? {
            guard httpResponse.statusCode != 200 else {
                return nil
            }
            
            return .other(String(httpResponse.statusCode))
        }
        
    }
    
}
