import Foundation
import CoreLocation

public final class SwiftLocation {
    
    /// Version of the SDK.
    public static let version = "6.0.0"
    
    // MARK: - Private Properties
    
    /// Underlying location manager implementation.
    private(set) var locationManager: LocationManagerProtocol
    
    /// Bridge for async/await communication via tasks.
    private(set) var asyncBridge: LocationAsyncBridge!

    /// The delegate which receive events from the underlying `locationManager` implementation
    /// and dispatch them to the `asyncBridge` through the final output function.
    private(set) var locationDelegate: LocationDelegate
    
    private let cache = UserDefaults(suiteName: "com.swiftlocation.cache")
    private let locationCacheKey = "lastLocation"

    // MARK: - Public Properties
    
    /// The last received location from underlying Location Manager service.
    /// This is persistent between sesssions and store the latest result with no
    /// filters or logic behind.
    public internal(set) var lastLocation: CLLocation? {
        get {
            cache?.location(forKey: locationCacheKey)
        }
        set {
            cache?.set(location: newValue, forKey: locationCacheKey)
        }
    }
    
    /// Indicate whether location services are enabled on the device.
    ///
    /// NOTE:
    /// This is an async function in order to prevent warning from the compiler.
    public var locationServicesEnabled: Bool {
        get async {
            await Task.detached {
                self.locationManager.locationServicesEnabled()
            }.value
        }
    }
    
    /// The status of your app’s authorization to provide parental controls.
    public var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    /// Indicates the level of location accuracy the app has permission to use.
    public var accuracyAuthorization: CLAccuracyAuthorization {
        locationManager.accuracyAuthorization
    }
    
    /// Indicates the accuracy of the location data that your app wants to receive.
    public var accuracy: LocationAccuracy {
        get { .init(level: locationManager.desiredAccuracy) }
        set { locationManager.desiredAccuracy = newValue.level }
    }
    
    /// The type of activity the app expects the user to typically perform while in the app’s location session.
    /// By default is set to `CLActivityType.other`.
    public var activityType: CLActivityType {
        get { locationManager.activityType }
        set { locationManager.activityType = newValue }
    }
    
    /// The minimum distance in meters the device must move horizontally before an update event is generated.
    /// By defualt is set to `kCLDistanceFilterNone`.
    ///
    /// NOTE:
    /// Use this property only in conjunction with the Standard location services and not with the Significant-change or Visits services.
    public var distanceFilter: CLLocationDistance {
        get { locationManager.distanceFilter }
        set { locationManager.distanceFilter = newValue }
    }
    
    /// Indicates whether the app receives location updates when running in the background.
    /// By default is `false`.
    ///
    /// NOTE:
    /// You must set the `UIBackgroundModes` in your `Info.plist` file in order to support this mode.
    ///
    /// When the value of this property is true and you start location updates while the app is in the foreground,
    /// Core Location configures the system to keep the app running to receive continuous background location updates,
    /// and arranges to show the background location indicator (blue bar or pill) if needed.
    /// Updates continue even if the app subsequently enters the background.
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set { locationManager.allowsBackgroundLocationUpdates = newValue }
    }
    
    // MARK: - Initialization
    
    /// Initialize a new SwiftLocation instance to work with the Core Location service.
    /// 
    /// - Parameter locationManager: underlying service. By default the device's CLLocationManager instance is used
    ///                              but you can provide your own.
    /// - Parameter allowsBackgroundLocationUpdates: Use this property to enable and disable background updates programmatically.
    ///                                              By default is `false`. Read the documentation to configure the environment correctly.
    public init(locationManager: LocationManagerProtocol = CLLocationManager(),
                allowsBackgroundLocationUpdates: Bool = false) {
        self.locationDelegate = LocationDelegate(asyncBridge: self.asyncBridge)
        self.locationManager = locationManager
        self.locationManager.delegate = locationDelegate
        self.locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.asyncBridge = LocationAsyncBridge(location: self)
    }
    
    // MARK: - Monitor Location Services Enabled
    
    /// Initiate a new async stream to monitor the status of the location services.
    /// - Returns: observable async stream.
    public func startMonitoringLocationServices() async -> Tasks.LocationServicesEnabled.Stream {
        let task = Tasks.LocationServicesEnabled()
        return Tasks.LocationServicesEnabled.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringLocationServices()
            }
        }
    }
    
    /// Stop observing the location services status updates.
    public func stopMonitoringLocationServices() {
        asyncBridge.cancel(tasksTypes: Tasks.LocationServicesEnabled.self)
    }
    
    // MARK: - Monitor Authorization Status

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
    
    // MARK: - Monitor Accuracy Authorization
    
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
    
    // MARK: - Request Permission for Location
    
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
    
    // MARK: - Monitor Location Updates
    
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
    
    // MARK: - Get Location
    
    public func requestLocation(accuracy filters: AccuracyFilters? = nil,
                                timeout: TimeInterval? = nil) async throws -> Tasks.ContinuousUpdateLocation.StreamEvent {
        
        // Setup the desidered accuracy based upon the highest resolution.
        locationManager.desiredAccuracy = AccuracyFilters.highestAccuracyLevel(currentLevel: locationManager.desiredAccuracy, filters: filters)
        let task = Tasks.SingleUpdateLocation(instance: self, accuracy: filters, timeout: timeout)
        return try await withTaskCancellationHandler {
            try await task.run()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    // MARK: - Monitor Regions
    
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
    
    // MARK: - Monitor Visits Updates
    
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
    
    // MARK: - Monitor Significant Locations
    
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
    
    // MARK: - Monitor Device Heading Updates
    
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
    
    // MARK: - Monitor Beacons Ranging
    
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
        
    // MARK: - Private Functions
    
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
