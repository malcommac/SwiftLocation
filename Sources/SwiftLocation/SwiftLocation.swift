import Foundation
import CoreLocation

public final class SwiftLocation {
    
    static let version = "6.0.0"
    
    private(set) var locationManager: LocationManagerProtocol
    private(set) var asyncBridge: LocationAsyncBridge!
    private(set) var locationDelegate: LocationDelegate
    
    private let cache = UserDefaults(suiteName: "com.swiftlocation.cache")
    private let locationCacheKey = "lastLocation"

    public internal(set) var lastLocation: CLLocation? {
        get {
            cache?.location(forKey: locationCacheKey)
        }
        set {
            cache?.set(location: newValue, forKey: locationCacheKey)
        }
    }
    
    public init(locationManager: LocationManagerProtocol = CLLocationManager()) {
        self.locationDelegate = LocationDelegate(asyncBridge: self.asyncBridge)
        self.locationManager = locationManager
        self.locationManager.delegate = locationDelegate
        self.asyncBridge = LocationAsyncBridge(location: self)
    }
    
    public func locationServicesEnabled() async -> Bool {
        // Avoid calling it from the main thread to prevent the runtime warning
        // about an unresponsive UI.
        // By using 'detached,' we can ensure that we're not on the main thread.
        await Task.detached {
            self.locationManager.locationServicesEnabled()
        }.value
    }
    
    public var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    public var accuracyAuthorization: CLAccuracyAuthorization {
        locationManager.accuracyAuthorization
    }
    
    public var accuracy: LocationAccuracy {
        get {
            .init(level: locationManager.desiredAccuracy)
        }
        set {
            locationManager.desiredAccuracy = newValue.level
        }
    }
    
    public func startMonitoringLocation() async -> Tasks.LocationServicesEnabled.Stream {
        let task = Tasks.LocationServicesEnabled()
        return Tasks.LocationServicesEnabled.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringLocationEnabled()
            }
        }
    }
    
    public func stopMonitoringLocationEnabled() {
        asyncBridge.cancel(tasksTypes: Tasks.LocationServicesEnabled.self)
    }

    public func startMonitoringAuthorization() async -> Tasks.Authorization.Stream {
        let task = Tasks.Authorization()
        return Tasks.Authorization.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringAuthorization()
            }
        }
    }
    
    public func stopMonitoringAuthorization() {
        asyncBridge.cancel(tasksTypes: Tasks.Authorization.self)
    }
    
    public func startMonitoringAccuracyAuthorization() async -> Tasks.AccuracyAuthorization.Stream {
        let task = Tasks.AccuracyAuthorization()
        return Tasks.AccuracyAuthorization.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringAccuracyAuthorization()
            }
        }
    }
    
    public func stopMonitoringAccuracyAuthorization() {
        asyncBridge.cancel(tasksTypes: Tasks.AccuracyAuthorization.self)
    }
    
    public func requestPermission(_ permission: LocationPermission) async throws -> CLAuthorizationStatus {
        try checkPermissionOrThrow(permission)
        switch permission {
        case .whenInUse:
            return try await requestWhenInUsePermission()
        case .always:
            #if APPCLIP
            return try await requestWhenInUsePermission()
            #else
            return try await requestAlwaysPermission()
            #endif
        }
    }
    
    public func requestTemporaryPrecisionAuthorization(purpose key: String) async throws -> CLAccuracyAuthorization {
        if !Bundle.hasTemporaryPermission(purposeKey: key) {
            throw Errors.plistNotConfigured
        }
     
        return try await requestTemporaryPrecisionPermission(purposeKey: key)
    }
    
    public func startUpdatingLocation() async throws -> Tasks.ContinuousUpdateLocation.Stream {
        guard locationManager.authorizationStatus != .notDetermined else {
            throw Errors.authorizationRequired
        }
        
        guard locationManager.authorizationStatus.canMonitorLocation else {
            throw Errors.notAuthorized
        }
        
        let task = Tasks.ContinuousUpdateLocation(instance: self)
        return Tasks.ContinuousUpdateLocation.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            
            locationManager.startUpdatingLocation()
            stream.onTermination = { @Sendable _ in
                self.asyncBridge.cancel(task: task)
            }
        }
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        asyncBridge.cancel(tasksTypes: Tasks.ContinuousUpdateLocation.self)
    }
    
    public func requestLocation(accuracy: AccuracyFilters? = nil,
                                timeout: TimeInterval? = nil) async throws -> Tasks.ContinuousUpdateLocation.StreamEvent {
        let task = Tasks.SingleUpdateLocation(instance: self, accuracy: accuracy, timeout: timeout)
        return try await withTaskCancellationHandler {
            try await task.run()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    public func startMonitoring(region: CLRegion) async throws -> Tasks.RegionMonitoring.Stream {
        let task = Tasks.RegionMonitoring(instance: self, region: region)
        return Tasks.RegionMonitoring.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            locationManager.startMonitoring(for: region)
            stream.onTermination = { @Sendable _ in
                self.asyncBridge.cancel(task: task)
            }
        }
    }
    
    public func stopMonitoring(region: CLRegion) {
        asyncBridge.cancel(tasksTypes: Tasks.RegionMonitoring.self) {
            ($0 as! Tasks.RegionMonitoring).region == region
        }
    }
    
    // MARK: - Significant Location Monitoring
    
    public func startMonitoringVisits() async -> Tasks.VisitsMonitoring.Stream {
        let task = Tasks.VisitsMonitoring()
        return Tasks.VisitsMonitoring.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            locationManager.startMonitoringVisits()
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringVisits()
            }
        }
    }
    
    public func stopMonitoringVisits() {
        asyncBridge.cancel(tasksTypes: Tasks.VisitsMonitoring.self)
        locationManager.stopMonitoringVisits()
    }
    
    // MARK: - Significant Location Monitoring
    
    public func startMonitoringSignificantLocationChanges() async -> Tasks.SignificantLocationMonitoring.Stream {
        let task = Tasks.SignificantLocationMonitoring()
        return Tasks.SignificantLocationMonitoring.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            locationManager.startMonitoringSignificantLocationChanges()
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringSignificantLocationChanges()
            }
        }
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
        asyncBridge.cancel(tasksTypes: Tasks.SignificantLocationMonitoring.self)
    }
    
    // MARK: - Heading Updates
    
    public func startUpdatingHeading() async -> Tasks.HeadingMonitoring.Stream {
        let task = Tasks.HeadingMonitoring()
        return Tasks.HeadingMonitoring.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            locationManager.startUpdatingHeading()
            stream.onTermination = { @Sendable _ in
                self.stopUpdatingHeading()
            }
        }
    }
    
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        asyncBridge.cancel(tasksTypes: Tasks.HeadingMonitoring.self)
    }
    
    // MARK: - Beacons
    
    public func startRangingBeacons(satisfying: CLBeaconIdentityConstraint) async -> Tasks.BeaconMonitoring.Stream {
        let task = Tasks.BeaconMonitoring(satisfying: satisfying)
        return Tasks.BeaconMonitoring.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            locationManager.startRangingBeacons(satisfying: satisfying)
            stream.onTermination = { @Sendable _ in
                self.stopRangingBeacons(satisfying: satisfying)
            }
        }
    }
    
    public func stopRangingBeacons(satisfying: CLBeaconIdentityConstraint) {
        asyncBridge.cancel(tasksTypes: Tasks.BeaconMonitoring.self) {
            ($0 as! Tasks.BeaconMonitoring).satisfying == satisfying
        }
        locationManager.stopRangingBeacons(satisfying: satisfying)
    }
        
    // MARK: - Authorization (Private Functions)
    
    private func checkPermissionOrThrow(_ permission: LocationPermission) throws {
        switch permission {
        case .always:
            if !Bundle.hasAlwaysPermission() {
                throw Errors.plistNotConfigured
            }
        case .whenInUse:
            if !Bundle.hasWhenInUsePermission() {
                throw Errors.plistNotConfigured
            }
        }
    }

    private func requestTemporaryPrecisionPermission(purposeKey: String) async throws -> CLAccuracyAuthorization {
        let task = Tasks.AccuracyPermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestTemporaryPermission(purposeKey: purposeKey)
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    private func requestWhenInUsePermission() async throws -> CLAuthorizationStatus {
        let task = Tasks.LocatePermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestWhenInUsePermission()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    private func requestAlwaysPermission() async throws -> CLAuthorizationStatus {
        let task = Tasks.LocatePermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestAlwaysPermission()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
}
