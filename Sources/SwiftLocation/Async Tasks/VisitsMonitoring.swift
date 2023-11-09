import Foundation
import CoreLocation

extension Tasks {
    
    public final class VisitsMonitoring: AnyTask {
        
        // MARK: - Support Structures
        
        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>

        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {

            /// A new visit-related event was received.
            case didVisit(_ visit: CLVisit)
            
            /// Receive an error.
            case didFailWithError(_ error: Error)
            
            public var description: String {
                switch self {
                case .didVisit:
                    "didVisit"
                case let .didFailWithError(error):
                    "didFailWithError: \(error.localizedDescription)"
                }
            }
            
            public static func == (lhs: Tasks.VisitsMonitoring.StreamEvent, rhs: Tasks.VisitsMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didVisit(v1), let .didVisit(v2)):
                    return v1 == v2
                case (let .didFailWithError(e1), let .didFailWithError(e2)):
                    return e1.localizedDescription == e2.localizedDescription
                default:
                    return false
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
