//
//  Locator+Error.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation

/// List of all errors produced by the framework.
///
/// - `discardedData`: data was discarded because it was not accepted by the request.
/// - `timeout`: call did fail due timeout interval reached.
/// - `generic`: generic location manager error.
public enum LocatorErrors: LocalizedError, Equatable {
    case discardedData
    case timeout
    case generic(Error)
    
    public static func == (lhs: LocatorErrors, rhs: LocatorErrors) -> Bool {
        switch (lhs, rhs) {
        case (.discardedData, .discardedData):
            return true
        case (.timeout, .timeout):
            return true
        case (.generic(let e1), .generic(let e2)):
            return e1.localizedDescription == e2.localizedDescription
        default:
            return false
        }
    }
    
}
