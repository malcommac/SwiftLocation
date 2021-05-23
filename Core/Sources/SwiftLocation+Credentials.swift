//
//  SwiftLocation+Credentials.swift
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

/// Shortcut to credentials manager.
public var SharedCredentials = LocationManager.Credentials.shared

public extension LocationManager {
    
    class Credentials: Codable {
        
        /// Shared credentials store.
        static let shared = Credentials()
        
        /// Store
        public private(set) var keysStore = [ServiceName: String]()
        
        private init() { }
        
        /// Use subscript to set keys for service.
        public subscript(_ service: ServiceName) -> String {
            get {
                guard let key = keysStore[service] else {
                    return ""
                }
                
                return key
            }
            set {
                keysStore[service] = newValue
            }
        }
        
        /// Load existing or saved credentials data.
        /// - Parameter newStore: store with data.
        public func loadCredential(_ newStore: Credentials) {
            newStore.keysStore.forEach { item in
                keysStore[item.key] = item.value
            }
        }
        
    }
    
}

// MARK: - LocationManager.Credentials

public extension LocationManager.Credentials {
    
    enum ServiceName: String, Codable, CaseIterable, CustomStringConvertible {
        // Geocoder, Autocomplete Related
        case google
        case googleBundleRestrictionID
        case here
        case mapBox
        case openStreet
        
        // IP Related
        case ipData
        case ipGeolocation
        case ipInfo
        case ipify
        case ipStack
        
        public var description: String {
            rawValue
        }
        
    }
    
}

internal struct HTTPHeaders {
    static let googleBundleRestriction = "X-Ios-Bundle-Identifier"
}
