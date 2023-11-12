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
    
    public final class AccuracyAuthorization: AnyTask {
        
        // MARK: - Support Structures

        /// Stream produced by the task.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// A new change in accuracy level authorization has been captured.
            case didUpdateAccuracyAuthorization(_ accuracyAuthorization: CLAccuracyAuthorization)
            
            /// Return the accuracy authorization of the event
            var accuracyAuthorization: CLAccuracyAuthorization {
                switch self {
                case let .didUpdateAccuracyAuthorization(accuracyAuthorization):
                    accuracyAuthorization
                }
            }
            
            public var description: String {
                switch self {
                case .didUpdateAccuracyAuthorization:
                    return "didUpdateAccuracyAuthorization"
                }
            }
            
        }
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        // MARK: - Functions

        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .didChangeAccuracyAuthorization(let auth):
                stream?.yield(.didUpdateAccuracyAuthorization(auth))
            default:
                break
            }
        }
    }
    
}
