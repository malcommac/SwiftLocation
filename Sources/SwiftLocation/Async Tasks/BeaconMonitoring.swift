import Foundation
import CoreLocation

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
