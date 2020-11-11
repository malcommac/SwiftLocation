//
//  PartialAddressMatch+Google.swift
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

internal extension PartialAddressMatch {
    
    // MARK: - Init Google Data
    
    init?(google json: [String: Any]) {
        self.representedObject = json
        
        self.title = json.valueForKeyPath(keyPath: "structured_formatting.main_text") ?? ""
        self.subtitle = json.valueForKeyPath(keyPath: "structured_formatting.secondary_text") ?? ""
        self.id = json.valueForKeyPath(keyPath: "place_id") ?? ""
        self.termsMatches = PartialAddressMatch.parseTermsMatches(json.valueForKeyPath(keyPath: "terms"))

        self.titleHighlightRanges = PartialAddressMatch.parseMatchingStrings(json.valueForKeyPath(keyPath: "structured_formatting.main_text_matched_substrings"))
        self.subtitleHighlightRanges = PartialAddressMatch.parseMatchingStrings(json.valueForKeyPath(keyPath: "structured_formatting.secondary_text_matched_substrings"))
        
        self.types = json.valueForKeyPath(keyPath: "types")
    }
    
    static func fromGoogleList(_ rawList: [[String: Any]]?) -> [Autocomplete.Data] {
        let list: [Autocomplete.Data] = rawList?.compactMap( {
            guard let address = PartialAddressMatch(google: $0) else {
                return nil
            }
            
            return .partial(address)
        }) ?? []
        return list
    }
    
    // MARK: - Private Functions
    
    static private func parseTermsMatches(_ matches: [[String: Any]]?) -> [TermMatch]? {
        return matches?.compactMap { rawData in
            let value: String? = rawData.valueForKeyPath(keyPath: "value")
            let offset: Int? = rawData.valueForKeyPath(keyPath: "offset")
            guard let unwrapValue = value, let unwrapOffset = offset else {
                return nil
            }
            
            return TermMatch(value: unwrapValue, offset: unwrapOffset)
        }
    }
    
    static private func parseMatchingStrings(_ matches: [[String: Any]]?) -> [NSRange] {
        return matches?.compactMap { rawData in
            let offset: Int? = rawData.valueForKeyPath(keyPath: "offset")
            let length: Int? = rawData.valueForKeyPath(keyPath: "length")
            guard let unwrapOffset = offset, let unwrapLength = length else {
                return nil
            }
            
            return NSRange(location: unwrapOffset, length: unwrapLength)
        } ?? []
    }
    
}
