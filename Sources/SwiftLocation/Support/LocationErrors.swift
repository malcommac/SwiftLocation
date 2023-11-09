import Foundation

/// Throwable errors
enum LocationErrors: LocalizedError {
    
    /// Info.plist authorization are not correctly defined.
    case plistNotConfigured
    
    /// System location services are disabled by the user or not available.
    case locationServicesDisabled
    
    /// You must require location authorization from the user before executing the operation.
    case authorizationRequired
    
    /// Not authorized by the user.
    case notAuthorized
    
    /// Operation timeout.
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .plistNotConfigured:
            "Missing authorization into Info.plist"
        case .locationServicesDisabled:
            "Location services disabled/not available"
        case .authorizationRequired:
            "Location authorization not requested yet"
        case .notAuthorized:
            "Not Authorized"
        case .timeout:
            "Timeout"
        }
    }
    
}
