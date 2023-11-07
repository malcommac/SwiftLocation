import Foundation
import CoreLocation

extension Tasks {
    
    public final class ContinuousUpdateLocation: AnyTask {
        
        // MARK: - Support Structures

        /// Stream produced by the task.
        public typealias Stream = AsyncStream<StreamEvent>
        
        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
            
            /// Location updates did pause.
            case didPaused
            
            /// Location updates did resume.
            case didResume
            
            /// A new array of locations has been received.
            case didUpdateLocations(_ locations: [CLLocation])
            
            /// Something went wrong while reading new locations.
            case didFailed(_ error: Error)
            
            /// Return the location received by the event if it's a location event.
            /// In case of multiple events it will return the most recent one.
            public var location: CLLocation? {
                locations?.max(by: { $0.timestamp < $1.timestamp })
            }
            
            /// Return the list of locations received if the event is a location update.
            public var locations: [CLLocation]? {
                guard case .didUpdateLocations(let locations) = self else {
                    return nil
                }
                return locations
            }
            
            /// Error received if any.
            public var error: Error? {
                guard case .didFailed(let e) = self else {
                    return nil
                }
                return e
            }
            
            public var description: String {
                switch self {
                case .didPaused: "paused"
                case .didResume: "resume"
                case let .didFailed(e): "error \(e.localizedDescription)"
                case let .didUpdateLocations(l): "\(l.count) locations"
                }
            }
            
            public static func == (lhs: Tasks.ContinuousUpdateLocation.StreamEvent, rhs: Tasks.ContinuousUpdateLocation.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (.didFailed(let e1), .didFailed(let e2)):
                    return e1.localizedDescription == e2.localizedDescription
                case (.didPaused, .didPaused):
                    return true
                case (.didResume, .didResume):
                    return true
                case (.didUpdateLocations(let l1), .didUpdateLocations(let l2)):
                    return l1 == l2
                default:
                    return false
                }
            }
        }
        
        // MARK: - Public Properties
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        // MARK: - Private Properties

        private weak var instance: Location?
        
        // MARK: - Initialization

        init(instance: Location) {
            self.instance = instance
        }
        
        // MARK: - Functions

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
