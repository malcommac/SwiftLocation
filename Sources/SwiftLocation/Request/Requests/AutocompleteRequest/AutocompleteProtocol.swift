//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

// MARK: - AutocompleteProtocol

public protocol AutocompleteProtocol: class {
    
    /// Execute the search.
    /// - Parameter completion: completion callback.
    func execute(_ completion: @escaping ((Result<[Autocomplete.AutocompleteResult], LocatorErrors>) -> Void))
    
    /// Cancel the operation.
    func cancel()
    
    /// Return `true` if operation was cancelled.
    var isCancelled: Bool { get }
    
}

/// Service Umbrella
public enum Autocomplete { }

// MARK: - Internal

/// Autocomplete search type based upon the search type.
internal enum AutocompleteOp {
    case partialMatch(String)
    case addressDetail(String)
}

// MARK: - Autocomplete.AutocompleteResult

public extension Autocomplete {
    
    /// Type of results for autocomplete call.
    /// - `partial`: result for partial address search.
    /// - `place`: result for full address detail returned from partial search.
    enum AutocompleteResult {
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
    
}
