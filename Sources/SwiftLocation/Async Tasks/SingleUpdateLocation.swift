import Foundation
import CoreLocation

extension Tasks {
    
    public final class SingleUpdateLocation: AnyTask {
        
        // MARK: - Support Structures

        public typealias Continuation = CheckedContinuation<ContinuousUpdateLocation.StreamEvent, Error>
        
        // MARK: - Public Properties

        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        // MARK: - Private Properties

        private var accuracyFilters: AccuracyFilters?
        private var timeout: TimeInterval?
        private weak var instance: Location?
        
        // MARK: - Initialization

        init(instance: Location, accuracy: AccuracyFilters?, timeout: TimeInterval?) {
            self.instance = instance
            self.accuracyFilters = accuracy
            self.timeout = timeout
        }
        
        // MARK: - Functions

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
                
                continuation?.resume(returning: .didUpdateLocations(filteredLocations))
                continuation = nil
                cancellable?.cancel(task: self)
            case let .didFailWithError(error):
                continuation?.resume(returning: .didFailed(error))
                continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        public func didCancelled() {
            continuation = nil
        }
        
        public func willStart() {
            guard let timeout else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.continuation?.resume(throwing: LocationErrors.timeout)
            }
        }
    }
    
}
