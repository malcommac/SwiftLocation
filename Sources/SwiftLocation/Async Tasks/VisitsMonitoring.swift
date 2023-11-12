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
    
    public final class VisitsMonitoring: AnyTask {
        
        // MARK: - Support Structures
        
        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {

            /// A new visit-related event was received.
            case didVisit(_ visit: CLVisit)
            
            /// Receive an error.
            case didFailWithError(_ error: Error)
            
            public var description: String {
                switch self {
                case .didVisit:
                    "didVisit"
                case let .didFailWithError(error):
                    "didFailWithError: \(error.localizedDescription)"
                }
            }
            
            public static func == (lhs: Tasks.VisitsMonitoring.StreamEvent, rhs: Tasks.VisitsMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didVisit(v1), let .didVisit(v2)):
                    return v1 == v2
                case (let .didFailWithError(e1), let .didFailWithError(e2)):
                    return e1.localizedDescription == e2.localizedDescription
                default:
                    return false
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
            case let .didVisit(visit):
                stream?.yield(.didVisit(visit))
            case let .didFailWithError(error):
                stream?.yield(.didFailWithError(error))
            default:
                break
            }
        }
    }
    
}
