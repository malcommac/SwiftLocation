import Foundation
import CoreLocation

extension Tasks {
    
    public final class LocationServicesEnabled: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didChangeLocationEnabled(_ enabled: Bool)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .didChangeLocationEnabled(let enabled):
                stream?.yield(.didChangeLocationEnabled(enabled))
            default:
                break
            }
        }
        
    }
    
}
