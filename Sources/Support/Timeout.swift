//
//  TimeoutManager.swift
//  SwiftLocation
//
//  Created by dan on 14/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation

public class Timeout {
    
    public enum Mode {
        case absolute(TimeInterval)
        case delayed(TimeInterval)
        
        public var interval: TimeInterval {
            switch self {
            case .absolute(let v): return v
            case .delayed(let v): return v
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
