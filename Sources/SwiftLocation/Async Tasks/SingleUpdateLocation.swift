import Foundation
import CoreLocation

extension Tasks {
    
    public final class SingleUpdateLocation: AnyTask {
        public typealias Continuation = CheckedContinuation<ContinuousUpdateLocation.StreamEvent, Error>
        
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        private var accuracyFilters: AccuracyFilters?
        private var timeout: TimeInterval?
        private var timer: Timer?
        private weak var instance: Location?
        
        init(instance: Location, accuracy: AccuracyFilters?, timeout: TimeInterval?) {
            self.instance = instance
            self.accuracyFilters = accuracy
            self.timeout = timeout
        }
        
        func run() async throws -> ContinuousUpdateLocation.StreamEvent {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }

                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestLocation()
            }
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case let .receiveNewLocations(locations):
                let filteredLocations = AccuracyFilter.filteredLocations(locations, withAccuracyFilters: accuracyFilters)
                guard filteredLocations.isEmpty == false else {
                    return // none of the locations respect passed filters
                }
                
                continuation?.resume(returning: .didUpdateLocations(locations))
                continuation = nil
                cancellable?.cancel(task: self)
            case let .didFailWithError(error):
                continuation?.resume(throwing: error)
                continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        public func didCancelled() {
            timer?.invalidate()
            timer = nil
            continuation = nil
        }
        
        public func willStart() {
            guard let timeout else {
                return
            }
            
            self.timer = Timer(timeInterval: timeout, repeats: false, block: { [weak self] _ in
                self?.continuation?.resume(throwing: Errors.timeout)
            })
        }
    }
    
}
