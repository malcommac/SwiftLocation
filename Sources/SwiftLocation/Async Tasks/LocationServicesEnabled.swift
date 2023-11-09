import Foundation
import CoreLocation

extension Tasks {
    
    public final class LocationServicesEnabled: AnyTask {
        
        // MARK: - Support Structures
        
        /// Stream produced by the task.
        public typealias Stream = AsyncStream<StreamEvent>
        
        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// A new change in the location services status has been detected.
            case didChangeLocationEnabled(_ enabled: Bool)
            
            /// Return `true` if location service is enabled.
            var isLocationEnabled: Bool {
                switch self {
                case let .didChangeLocationEnabled(enabled):
                    enabled
                }
            }
            
            public var description: String {
                switch self {
                case .didChangeLocationEnabled:
                    return "didChangeLocationEnabled"
                    
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
            case .didChangeLocationEnabled(let enabled):
                stream?.yield(.didChangeLocationEnabled(enabled))
            default:
                break
            }
        }
        
    }
    
}
