import Foundation
import CoreLocation

extension Tasks {
    
    public final class AccuracyAuthorization: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didUpdateAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
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
