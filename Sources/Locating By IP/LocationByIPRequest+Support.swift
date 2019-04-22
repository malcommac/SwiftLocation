//
//  LocationByIPRequest+Support.swift
//  SwiftLocation
//
//  Created by dan on 19/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation

public extension LocationByIPRequest {
    
    enum Service: CustomStringConvertible {
        case ipAPI
        case ipApiCo
        
        public var description: String {
            switch self {
            case .ipAPI:
                return "ipAPI"
            case .ipApiCo:
                return "ipApiCo"
            }
        }
    }
    
}
