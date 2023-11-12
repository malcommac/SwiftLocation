//
//  SwiftLocation
//  Async/Await Wrapper for CoreLocation
//
//  Copyright (c) 2023 Daniele Margutti (hello@danielemargutti.com).
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
