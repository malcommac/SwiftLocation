import Foundation
import CoreLocation

extension Tasks {
    
    public final class AccuracyPermission: AnyTask {
        public typealias Continuation = CheckedContinuation<CLAccuracyAuthorization, Error>
        
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        private weak var instance: Location?
        
        init(instance: Location) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .didChangeAccuracyAuthorization(let auth):
                continuation?.resume(with: .success(auth))
            default:
                break
            }
        }
        
        func requestTemporaryPermission(purposeKey: String) async throws -> CLAccuracyAuthorization {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                guard Bundle.hasTemporaryPermission(purposeKey: purposeKey) else {
                    continuation.resume(throwing: Errors.plistNotConfigured)
                    return
                }
                
                guard instance.locationManager.locationServicesEnabled() else {
                    continuation.resume(throwing: Errors.locationServicesDisabled)
                    return
                }
                
                let authorizationStatus = instance.authorizationStatus
                guard authorizationStatus != .notDetermined else {
                    continuation.resume(throwing: Errors.authorizationRequired)
                    return
                }
                
                let accuracyAuthorization = instance.accuracyAuthorization
                guard accuracyAuthorization != .fullAccuracy else {
                    continuation.resume(with: .success(accuracyAuthorization))
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // If the user chooses reduced accuracy, the didChangeAuthorization delegate method will not called.
                    if instance.locationManager.accuracyAuthorization == .reducedAccuracy {
                        let accuracyAuthorization = instance.accuracyAuthorization
                        instance.asyncBridge.dispatchEvent(.didChangeAccuracyAuthorization(accuracyAuthorization))
                    }
                }
            }
        }
        
    }
    
}
