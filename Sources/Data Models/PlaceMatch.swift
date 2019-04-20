//
//  PlaceMatch.swift
//  SwiftLocation
//
//  Created by dan on 18/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import Contacts

public enum PlaceMatch {
    case partialMatch(PlacePartialMatch)
    case fullMatch(Place)
    
    public var fullMatch: Place? {
        guard case .fullMatch(let v) = self else {
            return nil
        }
        return v
    }
    
    public var partialMatch: PlacePartialMatch? {
        guard case .partialMatch(let v) = self else {
            return nil
        }
        return v
    }
    
}

public class PlacePartialMatch {
    public let title: String
    public let subtitle: String
    
    public var titleHighlightRanges: [NSRange]?
    public var subtitleHighlightRanges: [NSRange]?
    
    internal init(localSearchCompletion: MKLocalSearchCompletion) {
        self.title = localSearchCompletion.title
        self.subtitle = localSearchCompletion.subtitle
        self.titleHighlightRanges = localSearchCompletion.titleHighlightRanges.map( { $0.rangeValue })
        self.subtitleHighlightRanges = localSearchCompletion.subtitleHighlightRanges.map( { $0.rangeValue })
    }
    
    internal init(googleJSON json: Any) {
        self.title = valueAtKeyPath(root: json, ["structured_formatting","main_text"]) ?? ""
        self.subtitle = valueAtKeyPath(root: json, ["structured_formatting","secondary_text"]) ?? ""

        let rawTitleRanges: [Any]? = valueAtKeyPath(root: json, ["structured_formatting","main_text_matched_substrings"])
        self.titleHighlightRanges = PlacePartialMatch.parseGoogleJSONRanges(rawRanges: rawTitleRanges)
    }
    
    private static func parseGoogleJSONRanges(rawRanges: [Any]?) -> [NSRange] {
        let list: [NSRange]? = rawRanges?.compactMap { rawRangeNode in
            let offset: Int? = valueAtKeyPath(root: rawRangeNode, ["offset"])
            let length: Int? = valueAtKeyPath(root: rawRangeNode, ["length"])
            guard let o = offset, let l = length else {
                return nil
            }
            return NSMakeRange(o, l)
        }
        return list ?? []
    }
    
}
