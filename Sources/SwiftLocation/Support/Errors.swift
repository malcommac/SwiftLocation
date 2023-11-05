import Foundation

enum Errors: LocalizedError {
    case plistNotConfigured
    case locationServicesDisabled
    case authorizationRequired
    case notAuthorized
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
