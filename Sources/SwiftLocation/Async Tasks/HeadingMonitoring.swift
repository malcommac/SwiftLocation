import Foundation
import CoreLocation

extension Tasks {
    
    public final class HeadingMonitoring: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didUpdateHeading(_ heading: CLHeading)
            case didFailWithError(_ error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .didUpdateHeading(heading):
                stream?.yield(.didUpdateHeading(heading))
            case let .didFailWithError(error):
                stream?.yield(.didFailWithError(error))
            default:
                break
            }
        }
        
    }
    
}
