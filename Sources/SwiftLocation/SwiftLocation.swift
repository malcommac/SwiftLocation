import Foundation
import CoreLocation

public enum LocationManagerEvent {
    case didChangeLocationEnabled(_ enabled: Bool)
    case didChangeAuthorization(_ status: CLAuthorizationStatus)
    case didChangeAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)

}

public protocol LocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    var desiredAccuracy: CLLocationAccuracy { get set }

    func locationServicesEnabled() -> Bool
    func requestWhenInUseAuthorization()
}

public class FakeLocationManager: LocationManagerProtocol {
    
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
    
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    private weak var asyncBridge: LocationAsyncBridge?
    
    init(asyncBridge: LocationAsyncBridge) {
        self.asyncBridge = asyncBridge
        super.init()
    }
    
}

enum Errors: Error {
    
}

public final class SwiftLocation {
    
    static let version = "6.0.0"
    
    private var locationManager: LocationManagerProtocol
    private var asyncBridge = LocationAsyncBridge()
    private var locationDelegate: LocationDelegate
    
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
    
    public func requestAuthorization(_ authorization: LocationAuthorization) async -> CLAuthorizationStatus {
        switch authorization {
        case .whenInUse:
            await requestWhenInUseAuthorization()
        case .always:
            #if APPCLIP
            await requestWhenInUseAuthorization()
            #else
            await requestAlwaysAuthorization()
            #endif
        }
    }
    
    private func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let task = Tasks.WhenInUseAuthorization(currentAuthorization: authorizationStatus)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if authorizationStatus != .notDetermined {
                    continuation.resume(returning: authorizationStatus)
                    return
                }
                
                task.continuation = continuation
                asyncBridge.add(task: task)
                locationManager.requestWhenInUseAuthorization()
            }
        } onCancel: {
            asyncBridge.cancel(task: task)
        }
    }
    
    private func requestAlwaysAuthorization() async -> CLAuthorizationStatus {
        fatalError()
    }
    
}

public enum Tasks { }

extension Tasks {
    
    public class WhenInUseAuthorization: AnyTask {
        public typealias Continuation = CheckedContinuation<CLAuthorizationStatus, Never>
        
        private let currentAuthorization: CLAuthorizationStatus
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?

        public init(currentAuthorization: CLAuthorizationStatus) {
            self.currentAuthorization = currentAuthorization
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
}

public extension AnyTask {
    
    var taskType: ObjectIdentifier {
        ObjectIdentifier(Self.self)
    }
    
    func didCancelled() { }
    
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

public enum LocationAuthorization {
    case always
    case whenInUse
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
    
}
