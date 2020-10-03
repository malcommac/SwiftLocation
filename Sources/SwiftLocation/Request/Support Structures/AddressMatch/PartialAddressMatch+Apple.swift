//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation
import MapKit

internal extension PartialAddressMatch {
    
    /// Initialize a new address match from Apple.
    /// - Parameter data: data.
    init(apple data: MKLocalSearchCompletion) {
        self.representedObject = data
       
        self.id = nil
        self.title = data.title
        self.subtitle = data.subtitle
        self.titleHighlightRanges = data.titleHighlightRanges.map( { $0.rangeValue })
        self.subtitleHighlightRanges = data.subtitleHighlightRanges.map( { $0.rangeValue })
        self.termsMatches = nil
        self.types = nil
    }
    
    static func fromAppleList(_ completer: MKLocalSearchCompleter) -> [Autocomplete.Data] {
        completer.results.map( { .partial(PartialAddressMatch(apple: $0)) })
    }
    
}
