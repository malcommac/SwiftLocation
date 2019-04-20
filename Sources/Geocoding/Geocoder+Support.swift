
//
//  sUPPORT.swift
//  SwiftLocation-iOS
//
//  Created by dan on 18/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation

public extension GeocoderRequest {
    
    /// Service to use.
    ///
    /// - apple: apple service.
    /// - google: google service.
    /// - openStreet: open streep map service.
    enum Service {
        case apple(Options?)
        case google(GoogleOptions)
        case openStreet(OpenStreetOptions)
    }
    
    // MARK: - Geocoder Options -
    
    class Options {
        
        /// Additional custom paramters. It may override default service params
        public var params = [String: String]()
        
        /// Result's locale, by defualt is not set.
        ///
        /// Apple Service:
        /// The locale to use when returning the address information. You might specify a value for this parameter
        /// when you want the address returned in a locale that differs from the user's current language settings.
        /// Specify nil to use the user's default locale information. It's valid only if you are using apple services.
        public var locale: String?
        
        /// Return all the servicer params as query items.
        ///
        /// - Returns: [URLQueryItem]
        internal func serverParams() -> [URLQueryItem] {
            return params.map({ (key,value) in
                URLQueryItem(name: key, value: value)
            })
        }
    }
    
    // MARK: - Google Geocoder Options -
    
    class GoogleOptions: Options {
        
        /// Api key for google service. Its required.
        public var APIKey: String?
        
    }
    
    // MARK: - OpenStreet Geocoder Options -

    class OpenStreetOptions: Options {
        
        /// Override default service locale.
        public override var locale: String? {
            set {
                guard let localeID = newValue else {
                    self.params.removeValue(forKey: "accept-language")
                    return
                }
                self.params["accept-language"] = localeID
            }
            get {
                return self.params["accept-language"]
            }
        }
        
        /// Email address.
        /// If you are making large numbers of request please include a valid email address
        /// or alternatively include your email address as part of the User-Agent string.
        /// This information will be kept confidential and only used to contact you in the
        /// event of a problem, see Usage Policy for more details.
        public var email: String? {
            set {
                guard let limit = newValue else {
                    self.params.removeValue(forKey: "email")
                    return
                }
                self.params["email"] = String(limit)
            }
            get {
                return self.params["email"]
            }
        }
        
        /// Limit results.
        public var limit: Int? {
            set {
                guard let limit = newValue else {
                    self.params.removeValue(forKey: "limit")
                    return
                }
                self.params["limit"] = String(limit)
            }
            get {
                return (self.params["limit"] != nil ? Int(self.params["limit"]!) : nil)
            }
        }
        
        /// Also show details of the address.
        public var addressDetails: Bool? {
            set {
                guard let addressdetails = newValue else {
                    self.params.removeValue(forKey: "addressdetails")
                    return
                }
                self.params["addressdetails"] = (addressdetails ? "1" : "0")
            }
            get {
                return (self.params["addressdetails"] != nil ? Int(self.params["addressdetails"]!) == 1 : nil)
            }
        }
        
        override init() {
            super.init()
            self.params["limit"] = "10"
            self.params["addressdetails"] = "1"
        }
        
    }
    
    // MARK: - Private -
    
    /// Geocoder operation type.
    ///
    /// - geocoder: geocoder.
    /// - reverseGeocoder: reverse geocoder.
    internal enum OperationType {
        case geocoder
        case reverseGeocoder
    }
    
}
