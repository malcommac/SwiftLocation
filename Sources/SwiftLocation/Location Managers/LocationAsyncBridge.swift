import Foundation
import CoreLocation

/// This bridge is used to link the object which manage the underlying events
/// from `CLLocationManagerDelegate`.
final class LocationAsyncBridge: CancellableTask {
    
    // MARK: - Private Properties
    
    private var tasks = [AnyTask]()
    weak var location: Location?

    // MARK: - Internal function
    
    /// Add a new task to the queued operations to bridge.
    ///
    /// - Parameter task: task to add.
    func add(task: AnyTask) {
        task.cancellable = self
        tasks.append(task)
        task.willStart()
    }
    
    /// Cancel the execution of a task.
    ///
    /// - Parameter task: task to cancel.
    func cancel(task: AnyTask) {
        cancel(taskUUID: task.uuid)
    }
    
    /// Cancel the execution of a task with a given unique identifier.
    ///
    /// - Parameter uuid: unique identifier of the task to remove
    private func cancel(taskUUID uuid: UUID) {
        tasks.removeAll { task in
            if task.uuid == uuid {
                task.didCancelled()
                return true
            } else {
                return false
            }
        }
    }
    
    /// Cancel the task of the given class and optional validated condition.
    ///
    /// - Parameters:
    ///   - type: type of `AnyTask` conform task to remove.
    ///   - condition: optional condition to verify in order to cancel.
    func cancel(tasksTypes type: AnyTask.Type, condition: ((AnyTask) -> Bool)? = nil) {
        let typeToRemove = ObjectIdentifier(type)
        tasks.removeAll(where: {
            let isCorrectType = ($0.taskType == typeToRemove)
            let isConditionValid = (condition == nil ? true : condition!($0))
            let shouldRemove = (isCorrectType && isConditionValid)
            
            if shouldRemove {
                $0.didCancelled()
            }
            return shouldRemove
        })
    }
    
    /// Dispatch the event to the tasks.
    ///
    /// - Parameter event: event to dispatch.
    func dispatchEvent(_ event: LocationManagerBridgeEvent) {
        for task in tasks {
            task.receivedLocationManagerEvent(event)
        }
        
        // store cached location
        if case .receiveNewLocations(let locations) = event {
            location?.lastLocation = locations.last
        }
    }
    
}
