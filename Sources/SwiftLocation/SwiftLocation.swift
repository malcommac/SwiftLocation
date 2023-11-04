import Foundation
import CoreLocation

public enum LocationManagerEvent {
    case didChangeLocationEnabled(_ enabled: Bool)
    case didChangeAuthorization(_ status: CLAuthorizationStatus)
    case didChangeAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)

    case locationUpdatesPaused
    case locationUpdatesResumed
    case receiveNewLocations(locations: [CLLocation])

    case didFailWithError(_ error: Error)
}

public protocol LocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    var desiredAccuracy: CLLocationAccuracy { get set }
    
    func locationServicesEnabled() -> Bool
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)?)

    func startUpdatingLocation()
    func stopUpdatingLocation()
}

public class FakeLocationManager: LocationManagerProtocol {
    public func requestAlwaysAuthorization() {
        
    }
    
    public var authorizationStatus: CLAuthorizationStatus {
        .authorizedAlways
    }
    
    public weak var delegate: CLLocationManagerDelegate?
    
    public func locationServicesEnabled() -> Bool {
        false
    }
    
    public var desiredAccuracy: CLLocationAccuracy = 100.0
    
    public var accuracyAuthorization: CLAccuracyAuthorization {
        .fullAccuracy
    }
    
    public func requestWhenInUseAuthorization() {
        
    }
    
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)? = nil) {
        
    }
    
    public func startUpdatingLocation() {
        
    }
    
    public func stopUpdatingLocation() {
        
    }
    
    public init() {
        
    }
}

extension CLLocationManager: LocationManagerProtocol {
    
    public func locationServicesEnabled() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
}

final class LocationAsyncBridge: CancellableTask {
    
    var tasks = [AnyTask]()

    func add(task: AnyTask) {
        task.cancellable = self
        tasks.append(task)
        task.willStart()
    }
    
    func cancel(task: AnyTask) {
        cancel(taskUUID: task.uuid)
    }
    
    func cancel(taskUUID uuid: UUID) {
        tasks.removeAll { task in
            if task.uuid == uuid {
                task.didCancelled()
                return true
            } else {
                return false
            }
        }
    }
    
    func cancel(tasksTypes type: AnyTask.Type) {
        let typeToRemove = ObjectIdentifier(type)
        tasks.removeAll(where: {
            $0.taskType == typeToRemove
        })
    }
    
    func dispatchEvent(_ event: LocationManagerEvent) {
        for task in tasks {
            task.receivedLocationManagerEvent(event)
        }
    }
    
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    private weak var asyncBridge: LocationAsyncBridge?
    
    init(asyncBridge: LocationAsyncBridge) {
        self.asyncBridge = asyncBridge
        super.init()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.didChangeAuthorization(manager.authorizationStatus))
        asyncBridge?.dispatchEvent(.didChangeAccuracyAuthorization(manager.accuracyAuthorization))
        locationManagerDidChangeServicesEnabled()
    }
    
    private func locationManagerDidChangeServicesEnabled() {
        Task {
            let enabled = CLLocationManager.locationServicesEnabled()
            await MainActor.run {
                asyncBridge?.dispatchEvent(.didChangeLocationEnabled(enabled))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        asyncBridge?.dispatchEvent(.receiveNewLocations(locations: locations))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        asyncBridge?.dispatchEvent(.didFailWithError(error))
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesPaused)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        asyncBridge?.dispatchEvent(.locationUpdatesResumed)
    }
    
}

enum Errors: LocalizedError {
    case plistNotConfigured
    case locationServicesDisabled
    case authorizationRequired
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .plistNotConfigured:
            "Missing authorization into Info.plist"
        case .locationServicesDisabled:
            "Location services disabled/not available"
        case .authorizationRequired:
            "Location authorization not requested yet"
        case .notAuthorized:
            "Not Authorized"
        }
    }
    
}

public final class SwiftLocation {
    
    static let version = "6.0.0"
    
    private(set) var locationManager: LocationManagerProtocol
    private(set) var asyncBridge = LocationAsyncBridge()
    private(set) var locationDelegate: LocationDelegate
    
    public init(locationManager: LocationManagerProtocol = CLLocationManager()) {
        self.locationDelegate = LocationDelegate(asyncBridge: self.asyncBridge)
        self.locationManager = locationManager
        self.locationManager.delegate = locationDelegate
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
    
    public func startMonitoringLocation() async -> Tasks.LocationEnabled.Stream {
        let task = Tasks.LocationEnabled()
        return Tasks.LocationEnabled.Stream { stream in
            task.stream = stream
            asyncBridge.add(task: task)
            stream.onTermination = { @Sendable _ in
                self.stopMonitoringLocationEnabled()
            }
        }
    }
    
    public func stopMonitoringLocationEnabled() {
        asyncBridge.cancel(tasksTypes: Tasks.LocationEnabled.self)
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
    
    public func startUpdatingLocation() async throws -> Tasks.MonitoringUpdateLocation.Stream {
        guard locationManager.authorizationStatus != .notDetermined else {
            throw Errors.authorizationRequired
        }
        
        guard locationManager.authorizationStatus.canMonitorLocation else {
            throw Errors.notAuthorized
        }
        
        let task = Tasks.MonitoringUpdateLocation(instance: self)
        return Tasks.MonitoringUpdateLocation.Stream { stream in
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
        asyncBridge.cancel(tasksTypes: Tasks.MonitoringUpdateLocation.self)
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

public enum Tasks { }

extension Tasks {
    
    public class MonitoringUpdateLocation: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didPaused
            case didResume
            case didUpdateLocations(_ locations: [CLLocation])
            case didFailed(_ error: Error)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        private weak var instance: SwiftLocation?
        
        init(instance: SwiftLocation) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
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
    
    public class AccuracyPermission: AnyTask {
        public typealias Continuation = CheckedContinuation<CLAccuracyAuthorization, Error>
        
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        private weak var instance: SwiftLocation?
        
        init(instance: SwiftLocation) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
            switch event {
            case .didChangeAccuracyAuthorization(let auth):
                continuation?.resume(with: .success(auth))
            default:
                break
            }
        }
        
        func requestTemporaryPermission(purposeKey: String) async throws -> CLAccuracyAuthorization {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                guard Bundle.hasTemporaryPermission(purposeKey: purposeKey) else {
                    continuation.resume(throwing: Errors.plistNotConfigured)
                    return
                }
                
                guard instance.locationManager.locationServicesEnabled() else {
                    continuation.resume(throwing: Errors.locationServicesDisabled)
                    return
                }
                
                let authorizationStatus = instance.authorizationStatus
                guard authorizationStatus != .notDetermined else {
                    continuation.resume(throwing: Errors.authorizationRequired)
                    return
                }
                
                let accuracyAuthorization = instance.accuracyAuthorization
                guard accuracyAuthorization != .fullAccuracy else {
                    continuation.resume(with: .success(accuracyAuthorization))
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // If the user chooses reduced accuracy, the didChangeAuthorization delegate method will not called.
                    if instance.locationManager.accuracyAuthorization == .reducedAccuracy {
                        let accuracyAuthorization = instance.accuracyAuthorization
                        instance.asyncBridge.dispatchEvent(.didChangeAccuracyAuthorization(accuracyAuthorization))
                    }
                }
            }
        }
        
    }
        
    public class LocatePermission: AnyTask {
        public typealias Continuation = CheckedContinuation<CLAuthorizationStatus, Error>
        
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        private weak var instance: SwiftLocation?
        
        init(instance: SwiftLocation) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
            switch event {
            case .didChangeAuthorization(let authorization):
                guard let continuation = continuation else {
                    cancellable?.cancel(task: self)
                    return
                }
                
                continuation.resume(returning: authorization)
                self.continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        func requestWhenInUsePermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                guard Bundle.hasWhenInUsePermission() else {
                    continuation.resume(throwing: Errors.plistNotConfigured)
                    return
                }
                
                let isAuthorized = instance.authorizationStatus != .notDetermined
                guard !isAuthorized else {
                    continuation.resume(returning: instance.authorizationStatus)
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        func requestAlwaysPermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                guard Bundle.hasAlwaysPermission() else {
                    continuation.resume(throwing: Errors.plistNotConfigured)
                    return
                }
                
                let isAuthorized = instance.authorizationStatus != .notDetermined && instance.authorizationStatus != .authorizedWhenInUse
                guard !isAuthorized else {
                    continuation.resume(with: .success(instance.authorizationStatus))
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestAlwaysAuthorization()
            }
        }
        
    }
    
    public class AccuracyAuthorization: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didUpdateAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
            switch event {
            case .didChangeAccuracyAuthorization(let auth):
                stream?.yield(.didUpdateAccuracyAuthorization(auth))
            default:
                break
            }
        }
    }
    
    public class Authorization: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>

        public enum StreamEvent {
            case didChangeAuthorization(_ status: CLAuthorizationStatus)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
            switch event {
            case .didChangeAuthorization(let status):
                stream?.yield(.didChangeAuthorization(status))
            default:
                break
            }
        }
    }
    
    public class LocationEnabled: AnyTask {
        public typealias Stream = AsyncStream<StreamEvent>
        
        public enum StreamEvent {
            case didChangeLocationEnabled(_ enabled: Bool)
        }
        
        public let uuid = UUID()
        public var stream: Stream.Continuation?
        public var cancellable: CancellableTask?
        
        public func receivedLocationManagerEvent(_ event: LocationManagerEvent) {
            switch event {
            case .didChangeLocationEnabled(let enabled):
                stream?.yield(.didChangeLocationEnabled(enabled))
            default:
                break
            }
        }
        
    }
    
}

public protocol AnyTask: AnyObject {
    
    var cancellable: CancellableTask? { get set }
    var uuid: UUID { get }
    var taskType: ObjectIdentifier { get }
    
    func receivedLocationManagerEvent(_ event: LocationManagerEvent)
    func didCancelled()
    func willStart()
}

public extension AnyTask {
    
    var taskType: ObjectIdentifier {
        ObjectIdentifier(Self.self)
    }
    
    func didCancelled() { }
    
    func willStart() { }
    
}


public protocol CancellableTask: AnyObject {
    func cancel(task: any AnyTask)
}

public enum LocationAccuracy {
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
    case bestForNavigation
    case custom(Double)
    
    init(level: CLLocationAccuracy) {
        switch level {
        case kCLLocationAccuracyBest:                 self = .best
        case kCLLocationAccuracyNearestTenMeters:     self = .nearestTenMeters
        case kCLLocationAccuracyHundredMeters:        self = .hundredMeters
        case kCLLocationAccuracyKilometer:            self = .kilometer
        case kCLLocationAccuracyThreeKilometers:      self = .threeKilometers
        case kCLLocationAccuracyBestForNavigation:    self = .bestForNavigation
        default:                                      self = .custom(level)
        }
    }
    
    internal var level: CLLocationAccuracy {
        switch self {
        case .best:                 kCLLocationAccuracyBest
        case .nearestTenMeters:     kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:        kCLLocationAccuracyHundredMeters
        case .kilometer:            kCLLocationAccuracyKilometer
        case .threeKilometers:      kCLLocationAccuracyThreeKilometers
        case .bestForNavigation:    kCLLocationAccuracyBestForNavigation
        case .custom(let value):    value
        }
    }
}

public enum LocationPermission {
    case always
    case whenInUse
}

extension Bundle {
    
    private static let always = "NSLocationAlwaysUsageDescription"
    private static let whenInUse = "NSLocationAlwaysAndWhenInUseUsageDescription"
    private static let temporary = "NSLocationTemporaryUsageDescriptionDictionary"
    
    static func hasTemporaryPermission(purposeKey: String) -> Bool {
        guard let node = Bundle.main.object(forInfoDictionaryKey: temporary) as? NSDictionary,
              let value = node.object(forKey: purposeKey) as? String,
              value.isEmpty == false else {
            return false
        }
        return true
    }
    
    static func hasWhenInUsePermission() -> Bool {
        !(Bundle.main.object(forInfoDictionaryKey: whenInUse) as? String ?? "").isEmpty
    }
    
    static func hasAlwaysPermission() -> Bool {
        !(Bundle.main.object(forInfoDictionaryKey: always) as? String ?? "").isEmpty &&
        !( Bundle.main.object(forInfoDictionaryKey: whenInUse) as? String ?? "").isEmpty
    }
    
}

extension CLAccuracyAuthorization: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .fullAccuracy:
            "fullAccuracy"
        case .reducedAccuracy:
            "reducedAccuracy"
        @unknown default:
            "Unknown (\(rawValue))"
        }
    }
    
}

extension CLAuthorizationStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notDetermined:        "notDetermined"
        case .restricted:           "restricted"
        case .denied:               "denied"
        case .authorizedAlways:     "authorizedAlways"
        case .authorizedWhenInUse:  "authorizedWhenInUse"
        @unknown default:           "unknown"
        }
    }
    
    var canMonitorLocation: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            true
        default:
            false
        }
    }
    
}
