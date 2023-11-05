import Foundation
import CoreLocation

extension Tasks {
    
    public final class SignificantLocationMonitoring: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didPaused
            case didResume
            case didUpdateLocations(_ locations: [CLLocation])
            case didFailWithError(_ error: Error)
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
