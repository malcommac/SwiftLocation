//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

/// Type of results for autocomplete call.
/// - `partial`: result for partial address search.
/// - `place`: result for full address detail returned from partial search.
public enum AutocompleteResult {
    case partial(PartialAddressMatch)
    case place(GeoLocation)
    
    public var partialAddress: PartialAddressMatch? {
        switch self {
        case .partial(let a): return a
        default: return nil
        }
    }
    
    public var place: GeoLocation? {
        switch self {
        case .place(let p): return p
        default: return nil
        }
    }
    
}
