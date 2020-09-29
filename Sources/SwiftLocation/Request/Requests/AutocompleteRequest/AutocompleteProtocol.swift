//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

/// Autocomplete search type based upon the search type.
internal enum AutocompleteType {
    case partialMatch(String)
    case addressDetail(String)
}

// MARK: - AutocompleteProtocol

public protocol AutocompleteProtocol: class {
    
    /// Execute the search.
    /// - Parameter completion: completion callback.
    func execute(_ completion: @escaping ((Result<[AutocompleteResult], LocatorErrors>) -> Void))
    
    /// Cancel the operation.
    func cancel()
    
    /// Return `true` if operation was cancelled.
    var isCancelled: Bool { get }
    
}
