//
//  PartialAddressMatch+Here.swift
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
import MapKit

internal extension PartialAddressMatch {
    
    /// Initialize a new address match from Apple.
    /// - Parameter data: data.
    init?(here json: [String: Any]?) {
        guard let json = json else {
            return nil
        }
        
        let name: String? = json.valueForKeyPath(keyPath: "title")
        guard let title = name else {
            return nil
        }
        
        self.representedObject = json
       
        self.id = json.valueForKeyPath(keyPath: "id") ?? ""
        self.title = title
        self.subtitle = json.valueForKeyPath(keyPath: "address.label") ?? ""
        self.titleHighlightRanges = nil
        self.subtitleHighlightRanges = nil
        self.termsMatches = nil
        self.types = PartialAddressMatch.parseTypes(json.valueForKeyPath(keyPath: "categories"))
    }
    
    static func fromHereList(_ rawList: [[String: Any]]?) -> [Autocomplete.Data] {
        rawList?.compactMap( {
            guard let address = PartialAddressMatch(here: $0) else {
                return nil
            }
            
            return .partial(address)
        }) ?? []
    }
    
    // MARK: - Private Functions
    
    private static func parseTypes(_ json: [[String: Any]]?) -> [String]? {
        json?.compactMap({ rawItem in
            let name: String? = rawItem.valueForKeyPath(keyPath: "name")
            return name
        })
    }
        
}
