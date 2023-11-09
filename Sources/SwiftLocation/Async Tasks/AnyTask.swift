import Foundation

public enum Tasks { }

public protocol AnyTask: AnyObject {
    
    var cancellable: CancellableTask? { get set }
    var uuid: UUID { get }
    var taskType: ObjectIdentifier { get }
    
    func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent)
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
