import Foundation
import CoreLocation

extension Tasks {
    
    public final class HeadingMonitoring: AnyTask {
        
        // MARK: - Support Structures

        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>
        
        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// A new heading value has been received.
            case didUpdateHeading(_ heading: CLHeading)
            
            /// An error has occurred.
            case didFailWithError(_ error: Error)
            
            public static func == (lhs: Tasks.HeadingMonitoring.StreamEvent, rhs: Tasks.HeadingMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didUpdateHeading(h1), let .didUpdateHeading(h2)):
                    return h1 == h2
                    
                case (let .didFailWithError(e1), let .didFailWithError(e2)):
                    return e1.localizedDescription == e2.localizedDescription
                    
                default:
                    return false
                    
                }
            }
            
            public var description: String {
                switch self {
                case .didFailWithError:
                    return "didFailWithError"
                    
                case .didUpdateHeading:
                    return "didUpdateHeading"
                    
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
