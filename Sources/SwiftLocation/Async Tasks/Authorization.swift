import Foundation
import CoreLocation

extension Tasks {
    
    public final class Authorization: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didChangeAuthorization(_ status: CLAuthorizationStatus)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .didChangeAuthorization(let status):
                stream?.yield(.didChangeAuthorization(status))
            default:
                break
            }
        }
    }
    
}
