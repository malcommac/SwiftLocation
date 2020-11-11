//
//  PartialAddressMatch.swift
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
