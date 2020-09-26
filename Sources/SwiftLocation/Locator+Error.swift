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
/// - `authorizationNeeded`: no necessary authorization was granted. This typically pops when you set the
///                         `avoidRequestAuthorization = true` for a arequest and no auth is set yet.
/// - `internalError`: failed to build up request due to an error.
/// - `parsingError`: parsing error.
/// - `cancelled`: user cancelled the operation.
public enum LocatorErrors: LocalizedError, Equatable {
    case discardedData(DataDiscardReason)
    case timeout
    case generic(Error)
    case authorizationNeeded
    case internalError
    case parsingError
    case cancelled

    /// Is a discarded data error.
    internal var isDataDiscarded: Bool {
        switch self {
        case .discardedData: return true
        default:             return false
        }
    }
    
    // MARK: - Public variables
    
    /// Localized error description.
    public var errorDescription: String? {
        switch self {
        case .discardedData(_):     return "Data Discarded"
        case .timeout:              return "Timeout"
        case .generic(let e):       return e.localizedDescription
        case .authorizationNeeded:  return "Authorization Needed"
        case .internalError:        return "Internal Server Error"
        case .parsingError:         return "Parsing Error"
        case .cancelled:            return "User Cancelled"
        }
    }
    
    public static func == (lhs: LocatorErrors, rhs: LocatorErrors) -> Bool {
        switch (lhs, rhs) {
        case (.discardedData, .discardedData):
            return true
        case (.timeout, .timeout):
            return true
        case (.generic(let e1), .generic(let e2)):
            return e1.localizedDescription == e2.localizedDescription
        case (.internalError, .internalError):
            return true
        case (.parsingError, .parsingError):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
    
}

// MARK: - LocatorLogger

public class LocatorLogger {
    
    static var isEnabled = true
    private static var queue = DispatchQueue(label: "locator.logger", qos: .background)
    
    static func log(_ message: String) {
        guard isEnabled else { return }
        
        queue.sync {
            print(message)
        }
    }
    
}
