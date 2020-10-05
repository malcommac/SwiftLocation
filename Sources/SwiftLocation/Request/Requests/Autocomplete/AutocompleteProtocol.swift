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

public protocol AutocompleteProtocol: class, Codable {
    
    /// Execute the search.
    /// - Parameter completion: completion callback.
    func execute(_ completion: @escaping ((Result<[Autocomplete.Data], LocatorErrors>) -> Void))
    
    /// Cancel the operation.
    func cancel()
    
    /// Return `true` if operation was cancelled.
    var isCancelled: Bool { get }
    
    /// Kind of the request.
    var kind: AutocompleteKind { get }
    
}

// MARK: - AutocompleteKind

public enum AutocompleteKind: Int, Codable {
    case apple, google, here
}

// MARK: - Autocomplete.Data

public extension Autocomplete {
    
    /// Type of results for autocomplete call.
    /// - `partial`: result for partial address search.
    /// - `place`: result for full address detail returned from partial search.
    enum Data {
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

// MARK: - Internal

/// Autocomplete search type based upon the search type.
internal enum AutocompleteOp: Codable {
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
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case kind, value
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(value, forKey: .value)
    }
    
    // Decodable protocol
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        
        switch try container.decode(Int.self, forKey: .kind) {
        case 0: self = .addressDetail(value)
        case 1: self = .partialMatch(value)
        default: fatalError("Failed to decode AutocompleteOp")
        }
    }

}
