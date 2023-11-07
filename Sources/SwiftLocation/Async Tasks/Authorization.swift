import Foundation
import CoreLocation

extension Tasks {
    
    public final class Authorization: AnyTask {
        
        // MARK: - Support Structures

        /// Stream produced by the task.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent {
            
            /// Authorization did change with a new value
            case didChangeAuthorization(_ status: CLAuthorizationStatus)
            
            /// The current status of the authorization.
            public var authorizationStatus: CLAuthorizationStatus {
                switch self {
                case let .didChangeAuthorization(status):
                    status
                }
            }
            
        }
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        // MARK: - Functions

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
