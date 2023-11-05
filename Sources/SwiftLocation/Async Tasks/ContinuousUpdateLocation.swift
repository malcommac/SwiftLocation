import Foundation
import CoreLocation

extension Tasks {
    
    public final class ContinuousUpdateLocation: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didPaused
            case didResume
            case didUpdateLocations(_ locations: [CLLocation])
            case didFailed(_ error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        private weak var instance: SwiftLocation?
        
        init(instance: SwiftLocation) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .locationUpdatesPaused:
                stream?.yield(.didPaused)
                
            case .locationUpdatesResumed:
                stream?.yield(.didResume)
                
            case let .didFailWithError(error):
                stream?.yield(.didFailed(error))
                
            case let .receiveNewLocations(locations):
                stream?.yield(.didUpdateLocations(locations))
                
            default:
                break
            }
        }
        
        public func didCancelled() {
            guard let stream = stream else {
                return
            }
            
            stream.finish()
            self.stream = nil
        }
        
    }
    
    
}
