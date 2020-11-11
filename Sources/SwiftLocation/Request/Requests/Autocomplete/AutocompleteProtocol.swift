//
//  AutocompleteProtocol.swift
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

/// Service Umbrella
public enum Autocomplete { }

// MARK: - AutocompleteProtocol

public protocol AutocompleteProtocol: class, CustomStringConvertible {
    
    /// Execute the search.
    /// - Parameter completion: completion callback.
    func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocationError>) -> Void))
    
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
public enum AutocompleteOp: CustomStringConvertible {
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
    
    public var description: String {
        switch self {
        case .partialMatch(let a):     return "PART \(a)"
        case .addressDetail(let a):    return "DETL \(a)"
        }
    }

}
