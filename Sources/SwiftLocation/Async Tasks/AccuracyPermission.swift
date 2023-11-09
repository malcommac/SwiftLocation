import Foundation
import CoreLocation

extension Tasks {
    
    public final class AccuracyPermission: AnyTask {
        
        // MARK: - Support Structures

        public typealias Continuation = CheckedContinuation<CLAccuracyAuthorization, Error>
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        // MARK: - Private Properties

        private weak var instance: Location?
        
        // MARK: - Initialization

        init(instance: Location) {
            self.instance = instance
        }
        
        // MARK: - Functions
        
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
                
                guard instance.locationManager.locationServicesEnabled() else {
                    continuation.resume(throwing: LocationErrors.locationServicesDisabled)
                    return
                }
                
                let authorizationStatus = instance.authorizationStatus
                guard authorizationStatus != .notDetermined else {
                    continuation.resume(throwing: LocationErrors.authorizationRequired)
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
