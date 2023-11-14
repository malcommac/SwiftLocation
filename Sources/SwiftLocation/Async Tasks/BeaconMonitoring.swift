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

#if !os(watchOS) && !os(tvOS)
extension Tasks {
    
    public final class BeaconMonitoring: AnyTask {
        
        // MARK: - Support Structures

        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>
        
        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            case didRange(beacons: [CLBeacon], constraint: CLBeaconIdentityConstraint)
            case didFailRanginFor(constraint: CLBeaconIdentityConstraint, error: Error)
            
            public static func == (lhs: Tasks.BeaconMonitoring.StreamEvent, rhs: Tasks.BeaconMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didRange(b1, _), let .didRange(b2, _)):
                    return b1 == b2
                    
                case (let .didFailRanginFor(c1, _), let .didFailRanginFor(c2, _)):
                    return c1 == c2
                    
                default:
                    return false
                    
                }
            }
            
            public var description: String {
                switch self {
                case .didFailRanginFor:
                    return "didFailRanginFor"
                case .didRange:
                    return "didRange"
                }
            }
        }
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        public private(set) var satisfying: CLBeaconIdentityConstraint
        
        // MARK: - Initialization

        init(satisfying: CLBeaconIdentityConstraint) {
            self.satisfying = satisfying
        }
        
        // MARK: - Functions

        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .didRange(beacons, constraint):
                stream?.yield(.didRange(beacons: beacons, constraint: constraint))
            case let .didFailRanginFor(constraint, error):
                stream?.yield(.didFailRanginFor(constraint: constraint, error: error))
            default:
                break
            }
        }
        
    }
    
}
#endif
