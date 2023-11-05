import Foundation
import CoreLocation

final class LocationAsyncBridge: CancellableTask {
    
    var tasks = [AnyTask]()
    private weak var location: SwiftLocation?
    
    init(location: SwiftLocation) {
        self.location = location
    }

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
    
    func cancel(tasksTypes type: AnyTask.Type, condition: ((AnyTask) -> Bool)? = nil) {
        let typeToRemove = ObjectIdentifier(type)
        tasks.removeAll(where: {
            let isCorrectType = $0.taskType == typeToRemove
            
            guard let condition else {
                return isCorrectType
            }
            
            return (isCorrectType && condition($0))
        })
    }
    
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
