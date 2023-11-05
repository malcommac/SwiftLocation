import Foundation
import CoreLocation

extension Tasks {
    
    public final class BeaconMonitoring: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didRange(beacons: [CLBeacon], constraint: CLBeaconIdentityConstraint)
            case didFailRanginFor(constraint: CLBeaconIdentityConstraint, error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        public private(set) var satisfying: CLBeaconIdentityConstraint
        
        init(satisfying: CLBeaconIdentityConstraint) {
            self.satisfying = satisfying
        }
        
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
