//
//  File.swift
//  
//
//  Created by daniele on 29/09/2020.
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
