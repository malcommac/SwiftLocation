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
    
    public final class SignificantLocationMonitoring: AnyTask {
        
        // MARK: - Support Structures

        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// Location changes stream paused.
            case didPaused
            
            /// Location changes stream resumed.
            case didResume
            
            /// New locations received.
            case didUpdateLocations(_ locations: [CLLocation])
            
            /// An error has occurred.
            case didFailWithError(_ error: Error)
            
            public var description: String {
                switch self {
                case let .didFailWithError(error):
                    return "didFailWithError: \(error.localizedDescription)"
                case .didPaused:
                    return "didPaused"

                case .didResume:
                    return "didResume"

                case .didUpdateLocations:
                    return "didUpdateLocations"

                }
            }
            
            public static func == (lhs: Tasks.SignificantLocationMonitoring.StreamEvent, rhs: Tasks.SignificantLocationMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didFailWithError(e1), let .didFailWithError(e2)):
                    return e1.localizedDescription == e2.localizedDescription
                    
                case (let .didUpdateLocations(l1), let .didUpdateLocations(l2)):
                    return l1 == l2
                    
                case (.didPaused, .didPaused):
                    return true
                    
                case (.didResume, .didResume):
                    return true
                    
                default:
                    return false
                    
                }
            }
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .receiveNewLocations(locations):
                stream?.yield(.didUpdateLocations(locations))
            case .locationUpdatesPaused:
                stream?.yield(.didPaused)
            case .locationUpdatesResumed:
                stream?.yield(.didResume)
            case let .didFailWithError(error):
                stream?.yield(.didFailWithError(error))
            default:
                break
            }
        }
        
    }
    
}
