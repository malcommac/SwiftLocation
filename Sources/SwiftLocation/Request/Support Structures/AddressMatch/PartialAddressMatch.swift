//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

/// This is the structure returned when using autocomplete partial search request.
public struct PartialAddressMatch {
    
    /// Represented object which originate the instance. For example using Apple service it's the MKLocalSearchCompletion.
    public let representedObject: Any?
    
    /// Title of the match.
    public let title: String
    
    /// Subtitle of the match.
    public let subtitle: String
    
    /// Some services may return an unique identifier for match (Google).
    /// You can use it to get place details with `init(detailsFor:APIKey:)` call in `GoogleAutocomplete`.
    public let id: String
    
    /// Highlight ranges for title.
    public let titleHighlightRanges: [NSRange]?
    
    /// Highlight ranges for subtitle.
    public let subtitleHighlightRanges: [NSRange]?
    
    /// Found matches offset.
    /// NOTE: Not all services return this value.
    public let termsMatches: [TermMatch]?
    
    /// Identifiers of the match.
    /// NOTE: Not all services return this value.
    public let types: [String]?
    
}

// MARK: - PartialAddressMatch (TermMatch)

public extension PartialAddressMatch {
    
    struct TermMatch {
        public let value: String
        public let offset: Int
    }
    
}
