import Foundation
import CoreLocation

extension Tasks {
    
    public final class RegionMonitoring: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didEnterTo(region: CLRegion)
            case didExitTo(region: CLRegion)
            case didStartMonitoringFor(region: CLRegion)
            case monitoringDidFailFor(region: CLRegion?, error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        private weak var instance: Location?
        private(set) var region: CLRegion
        
        init(instance: Location, region: CLRegion) {
            self.instance = instance
            self.region = region
        }
        
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
