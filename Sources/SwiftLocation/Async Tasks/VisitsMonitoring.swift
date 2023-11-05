import Foundation
import CoreLocation

extension Tasks {
    
    public final class VisitsMonitoring: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didVisit(_ visit: CLVisit)
            case didFailWithError(_ error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
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
