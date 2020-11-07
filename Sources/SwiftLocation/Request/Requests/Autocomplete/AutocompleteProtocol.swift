//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

/// Service Umbrella
public enum Autocomplete { }

// MARK: - AutocompleteProtocol

public protocol AutocompleteProtocol: class, CustomStringConvertible {
    
    /// Execute the search.
    /// - Parameter completion: completion callback.
    func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocatorErrors>) -> Void))
    
    /// Cancel the operation.
    func cancel()
    
    /// Return `true` if operation was cancelled.
    var isCancelled: Bool { get }
    
    /// Type of autocomplete operation
    var operation: AutocompleteOp { get set }
    
    /// Timeout interval.
    var timeout: TimeInterval? { get set }
 
}

// MARK: - Autocomplete.Data

public extension Autocomplete {
    
    /// Type of results for autocomplete call.
    /// - `partial`: result for partial address search.
    /// - `place`: result for full address detail returned from partial search.
    enum Data: CustomStringConvertible {
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
        
        public var description: String {
            switch self {
            case .partial(let address): return address.id
            case .place(let place): return place.description
            }
        }
        
    }
    
}

// MARK: - Internal

/// Autocomplete search type based upon the search type.
public enum AutocompleteOp {
    case partialMatch(String)
    case addressDetail(String)
    
    // MARK: - Public Properties
    
    public var kind: Int {
        switch self {
        case .partialMatch:     return 0
        case .addressDetail:    return 1
        }
    }
    
    public var value: String {
        switch self {
        case .partialMatch(let a):     return a
        case .addressDetail(let a):    return a
        }
    }

}
