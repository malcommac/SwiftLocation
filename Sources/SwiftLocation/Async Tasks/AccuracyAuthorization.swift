import Foundation
import CoreLocation

extension Tasks {
    
    public final class AccuracyAuthorization: AnyTask {
        
        // MARK: - Support Structures

        /// Stream produced by the task.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// A new change in accuracy level authorization has been captured.
            case didUpdateAccuracyAuthorization(_ accuracyAuthorization: CLAccuracyAuthorization)
            
            /// Return the accuracy authorization of the event
            var accuracyAuthorization: CLAccuracyAuthorization {
                switch self {
                case let .didUpdateAccuracyAuthorization(accuracyAuthorization):
                    accuracyAuthorization
                }
            }
            
            public var description: String {
                switch self {
                case .didUpdateAccuracyAuthorization:
                    return "didUpdateAccuracyAuthorization"
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
            case .didChangeAccuracyAuthorization(let auth):
                stream?.yield(.didUpdateAccuracyAuthorization(auth))
            default:
                break
            }
        }
    }
    
}
