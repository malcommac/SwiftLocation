//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import CoreLocation

extension Sequence {
    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        var count = 0
        for element in self {
            if try predicate(element) {
                count += 1
            }
        }
        return count
    }
}

internal struct CLPlacemarkDictionaryKey {
    // Parse address data
    static let kAdministrativeArea    = "AdministrativeArea"
    static let kSubAdministrativeArea = "SubAdministrativeArea"
    static let kSubLocality           = "SubLocality"
    static let kState                 = "State"
    static let kStreet                = "Street"
    static let kThoroughfare          = "Thoroughfare"
    static let kFormattedAddressLines = "FormattedAddressLines"
    static let kSubThoroughfare       = "SubThoroughfare"
    static let kPostCodeExtension     = "PostCodeExtension"
    static let kCity                  = "City"
    static let kZIP                   = "ZIP"
    static let kCountry               = "Country"
    static let kCountryCode           = "CountryCode"
}

internal func valueAtKeyPath<T>(root: Any, fallback: T? = nil, _ components: [Any]) -> T? {
    guard components.isEmpty == false else {
        return nil
    }
    
    var current: Any? = root
    for component in components {
        switch (component, current)  {
        case (let index as Int, let list as Array<Any>):
            guard index >= 0, index < list.count else {
                fatalError("Invalid index \(index) for node with \(list.count) elements")
            }
            current = list[index]
        case (let key as String, let dict as Dictionary<String,Any>):
            current = dict[key]
            
        default:
            fatalError("Unsupported path type: \(type(of: component)) for node: \(type(of: current))")
        }
    }
    
    return (current as? T) ?? fallback
}

internal extension String {
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
}

internal extension CLPlacemark {
    
    func makeAddressString() -> String {
        // Unwrapping the optionals using switch statement
        switch (self.subThoroughfare, self.thoroughfare, self.locality, self.administrativeArea, self.postalCode, self.country) {
        case let (.some(subThoroughfare), .some(thoroughfare), .some(locality), .some(administrativeArea), .some(postalCode), .some(country)):
            return "\(subThoroughfare), \(thoroughfare), \(locality), \(administrativeArea), \(postalCode), \(country)"
        default:
            return ""
        }
    }
    
}
