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
    
    public final class LocatePermission: AnyTask {
        
        // MARK: - Support Structures

        public typealias Continuation = CheckedContinuation<CLAuthorizationStatus, Error>
        
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
            case .didChangeAuthorization(let authorization):
                guard let continuation = continuation else {
                    cancellable?.cancel(task: self)
                    return
                }
                
                guard authorization != .notDetermined else {
                    // The location manager can return .notDetermined before a user hits the location popup.
                    // This causes the await to return before a user has tapped a button on the popup, so we
                    // ignore it here. Once the user hits a button on the popup, receivedLocationManagerEvent will
                    // be called again with a better authorization.
                    return
                }
                
                continuation.resume(returning: authorization)
                self.continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        func requestWhenInUsePermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                let isAuthorized = instance.authorizationStatus != .notDetermined
                guard !isAuthorized else {
                    continuation.resume(returning: instance.authorizationStatus)
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        #if !os(tvOS)
        func requestAlwaysPermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                #if os(macOS)
                let isAuthorized = instance.authorizationStatus != .notDetermined
                #else
                let isAuthorized = instance.authorizationStatus != .notDetermined && instance.authorizationStatus != .authorizedWhenInUse
                #endif
                guard !isAuthorized else {
                    continuation.resume(with: .success(instance.authorizationStatus))
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestAlwaysAuthorization()
            }
        }
        #endif
        
    }
    
}
