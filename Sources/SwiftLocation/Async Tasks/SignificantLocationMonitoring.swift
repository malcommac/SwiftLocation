import Foundation
import CoreLocation

extension Tasks {
    
    public final class SignificantLocationMonitoring: AnyTask {
        
        // MARK: - Support Structures

        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// Location changes stream paused.
            case didPaused
            
            /// Location changes stream resumed.
            case didResume
            
            /// New locations received.
            case didUpdateLocations(_ locations: [CLLocation])
            
            /// An error has occurred.
            case didFailWithError(_ error: Error)
            
            public var description: String {
                switch self {
                case let .didFailWithError(error):
                    return "didFailWithError: \(error.localizedDescription)"
                case .didPaused:
                    return "didPaused"

                case .didResume:
                    return "didResume"

                case .didUpdateLocations:
                    return "didUpdateLocations"

                }
            }
            
            public static func == (lhs: Tasks.SignificantLocationMonitoring.StreamEvent, rhs: Tasks.SignificantLocationMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didFailWithError(e1), let .didFailWithError(e2)):
                    return e1.localizedDescription == e2.localizedDescription
                    
                case (let .didUpdateLocations(l1), let .didUpdateLocations(l2)):
                    return l1 == l2
                    
                case (.didPaused, .didPaused):
                    return true
                    
                case (.didResume, .didResume):
                    return true
                    
                default:
                    return false
                    
                }
            }
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
