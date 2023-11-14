//
//  SwiftLocation
//  Async/Await Wrapper for CoreLocation
//
//  Copyright (c) 2023 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation

/// Instantiate this class to query and setup the Location Services and all the function
/// of the library itself.
public final class Location {
    
    // MARK: - Private Properties
    
    /// Underlying location manager implementation.
    private(set) var locationManager: LocationManagerProtocol
    
    /// Bridge for async/await communication via tasks.
    private(set) var asyncBridge = LocationAsyncBridge()

    /// The delegate which receive events from the underlying `locationManager` implementation
    /// and dispatch them to the `asyncBridge` through the final output function.
    private(set) var locationDelegate: LocationDelegate
    
    /// Cache used to store some bits of the data retrived by the underlying core location service.
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
    
    #if !os(tvOS)
    /// The type of activity the app expects the user to typically perform while in the app’s location session.
    /// By default is set to `CLActivityType.other`.
    public var activityType: CLActivityType {
        get { locationManager.activityType }
        set { locationManager.activityType = newValue }
    }
    #endif
    
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
    #if !os(tvOS)
    public var allowsBackgroundLocationUpdates: Bool {
        get { locationManager.allowsBackgroundLocationUpdates }
        set { locationManager.allowsBackgroundLocationUpdates = newValue }
    }
    #endif
    
    // MARK: - Initialization
    
    #if !os(tvOS)
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
        self.asyncBridge.location = self
    }
    #else
    /// Initialize a new SwiftLocation instance to work with the Core Location service.
    ///
    /// - Parameter locationManager: underlying service. By default the device's CLLocationManager instance is used
    ///                              but you can provide your own.
    public init(locationManager: LocationManagerProtocol = CLLocationManager()) {
        self.locationDelegate = LocationDelegate(asyncBridge: self.asyncBridge)
        self.locationManager = locationManager
        self.locationManager.delegate = locationDelegate
        self.asyncBridge.location = self
    }
    #endif
    
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
    
    /// Monitor updates about the authorization status.
    ///
    /// - Returns: stream of authorization statuses.
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
    
    /// Stop monitoring changes of authorization status by stopping all running streams.
    public func stopMonitoringAuthorization() {
        asyncBridge.cancel(tasksTypes: Tasks.Authorization.self)
    }
    
    // MARK: - Monitor Accuracy Authorization
    
    /// Monitor accuracy authorization level.
    ///
    /// - Returns: a stream of statuses.
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
    
    /// Stop monitoring accuracy authorization status by stopping all running streams.
    public func stopMonitoringAccuracyAuthorization() {
        asyncBridge.cancel(tasksTypes: Tasks.AccuracyAuthorization.self)
    }
    
    // MARK: - Request Permission for Location
    
    /// Request to monitor location changes.
    ///
    /// - Parameter permission: type of permission you would to require.
    /// - Returns: obtained status.
    @discardableResult
    public func requestPermission(_ permission: LocationPermission) async throws -> CLAuthorizationStatus {
        try locationManager.validatePlistConfigurationOrThrow(permission: permission)
        
        switch permission {
        case .whenInUse:
            return try await requestWhenInUsePermission()
        #if !os(tvOS)
        case .always:
            #if APPCLIP
            return try await requestWhenInUsePermission()
            #else
            return try await requestAlwaysPermission()
            #endif
        #endif
        }
    }
    
    /// Temporary request the authorization to get precise location of the user.
    ///
    /// - Parameter key: purpose key used to prompt the user. Must be defined into the `Info.plist`.
    /// - Returns: obtained status.
    @discardableResult
    public func requestTemporaryPrecisionAuthorization(purpose key: String) async throws -> CLAccuracyAuthorization {
        try locationManager.validatePlistConfigurationForTemporaryAccuracy(purposeKey: key)
        return try await requestTemporaryPrecisionPermission(purposeKey: key)
    }
    
    // MARK: - Monitor Location Updates
    
    #if !os(tvOS)
    /// Start receiving changes of the locations with a stream.
    ///
    /// - Returns: events received from the location manager.
    public func startMonitoringLocations() async throws -> Tasks.ContinuousUpdateLocation.Stream {
        guard locationManager.authorizationStatus != .notDetermined else {
            throw LocationErrors.authorizationRequired
        }
        
        guard locationManager.authorizationStatus.canMonitorLocation else {
            throw LocationErrors.notAuthorized
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
    
    /// Stop updating location updates streams.
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        asyncBridge.cancel(tasksTypes: Tasks.ContinuousUpdateLocation.self)
    }
    #endif
    
    // MARK: - Get Location
    
    /// Request a one-shot location from the underlying core location service.
    ///
    /// - Parameters:
    ///   - filters: optional filters to receive only the first event which satisfy filters.
    ///   - timeout: timeout interval for the request.
    /// - Returns: event received.
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
    
    #if !os(watchOS) && !os(tvOS)
    // MARK: - Monitor Regions
    
    /// Starts the monitoring a region and receive stream of events from it.
    ///
    /// - Parameter region: region to monitor.
    /// - Returns: stream of events.
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
    
    /// Stop monitoring a region.
    ///
    /// - Parameter region: region.
    public func stopMonitoring(region: CLRegion) {
        asyncBridge.cancel(tasksTypes: Tasks.RegionMonitoring.self) {
            ($0 as! Tasks.RegionMonitoring).region == region
        }
    }
    #endif
    
    // MARK: - Monitor Visits Updates
    
    #if !os(watchOS) && !os(tvOS)
    /// Starts monitoring visits to locations.
    ///
    /// - Returns: stream of events for visits.
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
    
    /// Stop monitoring visits updates.
    public func stopMonitoringVisits() {
        asyncBridge.cancel(tasksTypes: Tasks.VisitsMonitoring.self)
        locationManager.stopMonitoringVisits()
    }
    #endif
    
    #if !os(watchOS) && !os(tvOS)
    // MARK: - Monitor Significant Locations
    
    /// Starts monitoring significant location changes.
    ///
    /// - Returns: stream of events of location changes.
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
    
    /// Stops monitoring location changes.
    public func stopMonitoringSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
        asyncBridge.cancel(tasksTypes: Tasks.SignificantLocationMonitoring.self)
    }
    #endif
    
    #if os(iOS)
    // MARK: - Monitor Device Heading Updates
    
    /// Starts monitoring heading changes.
    ///
    /// - Returns: stream of events for heading
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
    
    /// Stops monitoring device heading changes.
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        asyncBridge.cancel(tasksTypes: Tasks.HeadingMonitoring.self)
    }    
    #endif
    
    // MARK: - Monitor Beacons Ranging
    
    /// Starts the delivery of notifications for the specified beacon region.
    ///
    /// - Parameter satisfying: A `CLBeaconIdentityConstraint` constraint.
    /// - Returns: stream of events related to passed constraint.
    #if !os(watchOS) && !os(tvOS)
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
    
    /// Stops monitoring beacon ranging for passed constraint.
    ///
    /// - Parameter satisfying: A `CLBeaconIdentityConstraint` constraint.
    public func stopRangingBeacons(satisfying: CLBeaconIdentityConstraint) {
        asyncBridge.cancel(tasksTypes: Tasks.BeaconMonitoring.self) {
            ($0 as! Tasks.BeaconMonitoring).satisfying == satisfying
        }
        locationManager.stopRangingBeacons(satisfying: satisfying)
    }
    #endif
        
    // MARK: - Private Functions
    
    /// Request temporary increase of the precision.
    ///
    /// - Parameter purposeKey: purpose key.
    /// - Returns: authorization obtained.
    private func requestTemporaryPrecisionPermission(purposeKey: String) async throws -> CLAccuracyAuthorization {
        let task = Tasks.AccuracyPermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestTemporaryPermission(purposeKey: purposeKey)
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    /// Request authorization to get location when app is in use.
    ///
    /// - Returns: authorization obtained.
    private func requestWhenInUsePermission() async throws -> CLAuthorizationStatus {
        let task = Tasks.LocatePermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestWhenInUsePermission()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    #if !os(tvOS)
    /// Request authorization to get location both in foreground and background.
    ///
    /// - Returns: authorization obtained.
    private func requestAlwaysPermission() async throws -> CLAuthorizationStatus {
        let task = Tasks.LocatePermission(instance: self)
        return try await withTaskCancellationHandler {
            try await task.requestAlwaysPermission()
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    #endif
    
}
