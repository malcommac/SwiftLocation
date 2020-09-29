//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

internal extension PartialAddressMatch {
    
    // MARK: - Init Google Data
    
    init?(google json: [String: Any]) {
        self.representedObject = json
        
        self.title = json.valueForKeyPath(keyPath: "structured_formatting.main_text") ?? ""
        self.subtitle = json.valueForKeyPath(keyPath: "structured_formatting.secondary_text") ?? ""
        self.id = json.valueForKeyPath(keyPath: "place_id")
        self.termsMatches = PartialAddressMatch.parseTermsMatches(json.valueForKeyPath(keyPath: "terms"))

        self.titleHighlightRanges = PartialAddressMatch.parseMatchingStrings(json.valueForKeyPath(keyPath: "structured_formatting.main_text_matched_substrings"))
        self.subtitleHighlightRanges = PartialAddressMatch.parseMatchingStrings(json.valueForKeyPath(keyPath: "structured_formatting.secondary_text_matched_substrings"))
        
        self.types = json.valueForKeyPath(keyPath: "types")
    }
    
    static func fromGoogleList(_ rawList: [[String: Any]]?) -> [Autocomplete.AutocompleteResult] {
        let list: [Autocomplete.AutocompleteResult] = rawList?.compactMap( {
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
