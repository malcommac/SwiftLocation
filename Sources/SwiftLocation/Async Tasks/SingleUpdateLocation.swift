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
    
    public final class SingleUpdateLocation: AnyTask {
        
        // MARK: - Support Structures

        public typealias Continuation = CheckedContinuation<ContinuousUpdateLocation.StreamEvent, Error>
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        // MARK: - Private Properties

        private var accuracyFilters: AccuracyFilters?
        private var timeout: TimeInterval?
        private weak var instance: Location?
        
        // MARK: - Initialization

        init(instance: Location, accuracy: AccuracyFilters?, timeout: TimeInterval?) {
            self.instance = instance
            self.accuracyFilters = accuracy
            self.timeout = timeout
        }
        
        // MARK: - Functions

        func run() async throws -> ContinuousUpdateLocation.StreamEvent {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }

                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestLocation()
            }
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .receiveNewLocations(locations):
                let filteredLocations = AccuracyFilter.filteredLocations(locations, withAccuracyFilters: accuracyFilters)
                guard filteredLocations.isEmpty == false else {
                    return // none of the locations respect passed filters
                }
                
                continuation?.resume(returning: .didUpdateLocations(filteredLocations))
                continuation = nil
                cancellable?.cancel(task: self)
            case let .didFailWithError(error):
                continuation?.resume(returning: .didFailed(error))
                continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        public func didCancelled() {
            continuation = nil
        }
        
        public func willStart() {
            guard let timeout else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.continuation?.resume(throwing: LocationErrors.timeout)
            }
        }
    }
    
}
