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

/// This bridge is used to link the object which manage the underlying events
/// from `CLLocationManagerDelegate`.
final class LocationAsyncBridge: CancellableTask {
    
    // MARK: - Private Properties
    
    private var tasks = SynchronizedArray<AnyTask>()
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
        for task in tasks.originalArray {
            task.receivedLocationManagerEvent(event)
        }
        
        // store cached location
        if case .receiveNewLocations(let locations) = event {
            location?.lastLocation = locations.last
        }
    }
    
    /// Count the task of the given class
    ///
    /// - Parameters:
    ///   - type: type of `AnyTask` conform task to remove.
    func count(tasksTypes type: AnyTask.Type) -> Int {
        let typeToCount = ObjectIdentifier(type)
        return tasks.filter({ $0.taskType == typeToCount }).count
    }
}
