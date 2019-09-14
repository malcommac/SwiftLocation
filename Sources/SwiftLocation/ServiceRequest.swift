//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import CoreLocation

public enum RequestState: CustomStringConvertible {
    case idle
    case paused
    case running
    case expired
    
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .paused:
            return "paused"
        case .running:
            return "running"
        case .expired:
            return "expired"
        }
    }
    
    public var isRunning: Bool {
        guard case .running = self else {
            return false
        }
        return true
    }
    
    public var canReceiveEvents: Bool {
        guard case .paused = self else {
            return true
        }
        return false
    }
}

public protocol ServiceRequest {
    typealias RequestID = String

    var id: LocationManager.RequestID { get }
    var timeout: Timeout.Mode? { get }
    var state: RequestState { get }
    
    func stop()
    func start()
    func pause()

}
