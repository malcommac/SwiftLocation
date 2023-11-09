import Foundation
import CoreLocation

extension Tasks {
    
    public final class RegionMonitoring: AnyTask {
        
        // MARK: - Support Structures

        /// The event produced by the stream.
        public typealias Stream = AsyncStream<StreamEvent>
        
        /// The event produced by the stream.
        public enum StreamEvent: CustomStringConvertible, Equatable {
        
            /// User entered the specified region.
            case didEnterTo(region: CLRegion)
            
            /// User exited from the specified region.
            case didExitTo(region: CLRegion)
            
            /// A new region is being monitored.
            case didStartMonitoringFor(region: CLRegion)
            
            /// Specified  region monitoring error occurred.
            case monitoringDidFailFor(region: CLRegion?, error: Error)
            
            public var description: String {
                switch self {
                case .didEnterTo:
                    "didEnterRegion"
                case .didExitTo:
                    "didExitRegion"
                case .didStartMonitoringFor:
                    "didStartMonitoring"
                case let .monitoringDidFailFor(_, error):
                    "monitoringDidFail: \(error.localizedDescription)"
                }
            }
            
            public static func == (lhs: Tasks.RegionMonitoring.StreamEvent, rhs: Tasks.RegionMonitoring.StreamEvent) -> Bool {
                switch (lhs, rhs) {
                case (let .didEnterTo(r1), let .didEnterTo(r2)):
                    return r1 == r2
                case (let .didExitTo(r1), let .didExitTo(r2)):
                    return r1 == r2
                case (let .didStartMonitoringFor(r1), let .didStartMonitoringFor(r2)):
                    return r1 == r2
                case (let .monitoringDidFailFor(r1, e1), let .monitoringDidFailFor(r2, e2)):
                    return r1 == r2 || e1.localizedDescription == e2.localizedDescription
                default:
                    return false
                }
            }
            
        }
        
        // MARK: - Public Properties
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        private weak var instance: Location?
        private(set) var region: CLRegion
        
        // MARK: - Initialization

        init(instance: Location, region: CLRegion) {
            self.instance = instance
            self.region = region
        }
        
        // MARK: - Functions

        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .didStartMonitoringFor(region):
                stream?.yield(.didStartMonitoringFor(region: region))
                
            case let .didEnterRegion(region):
                stream?.yield(.didEnterTo(region: region))
                
            case let .didExitRegion(region):
                stream?.yield(.didExitTo(region: region))
                
            case let .monitoringDidFailFor(region, error):
                stream?.yield(.monitoringDidFailFor(region: region, error: error))
                
            default:
                break
                
            }
        }
        
    }
    
}
