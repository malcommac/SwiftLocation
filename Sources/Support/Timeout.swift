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

public class Timeout {
    
    public enum Mode: CustomStringConvertible {
        case absolute(TimeInterval)
        case delayed(TimeInterval)
        
        public var interval: TimeInterval {
            switch self {
            case .absolute(let v): return v
            case .delayed(let v): return v
            }
        }
        
        public var description: String {
            switch self {
            case .absolute(let t):
                return "abs \(t)s"
            case .delayed(let t):
                return "dly \(t)s"
            }
        }
        
    }
 
    public let mode: Mode
    internal var callback: ((TimeInterval) -> Void)?
    private var timer: Timer?

    public init(mode: Mode) {
        self.mode = mode
    }
    
    @discardableResult
    internal func startIfNeeded() -> Bool {
        switch (mode, LocationManager.state) {
        case (.absolute(let value), _), (.delayed(let value), .available):
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: value, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
            return true
        default:
            return false
        }
    }
    
    internal func reset() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timerFired() {
        callback?(mode.interval)
        reset()
    }
    
}
