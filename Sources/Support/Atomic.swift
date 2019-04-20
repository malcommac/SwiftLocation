//
//  SafeQueue.swift
//  SwiftLocation
//
//  Created by dan on 14/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import Dispatch

/// A wrapper for atomic read/write access to a value.
/// The value is protected by a serial `DispatchQueue`.
public final class Atomic<A> {
    private var _value: A
    private let queue: DispatchQueue
    
    /// Creates an instance of `Atomic` with the specified value.
    ///
    /// - Paramater value: The object's initial value.
    /// - Parameter targetQueue: The target dispatch queue for the "lock queue".
    ///   Use this to place the atomic value into an existing queue hierarchy
    ///   (e.g. for the subsystem that uses this object).
    ///   See Apple's WWDC 2017 session 706, Modernizing Grand Central Dispatch
    ///   Usage (https://developer.apple.com/videos/play/wwdc2017/706/), for
    ///   more information on how to use target queues effectively.
    ///
    ///   The default value is `nil`, which means no target queue will be set.
    public init(_ value: A, targetQueue: DispatchQueue? = nil) {
        _value = value
        queue = DispatchQueue(label: "com.olebegemann.Atomic", target: targetQueue)
    }
    
    /// Read access to the wrapped value.
    public var atomic: A {
        return queue.sync { _value }
    }
    
    /// Mutations of `value` must be performed via this method.
    ///
    /// If `Atomic` exposed a setter for `value`, constructs that used the getter
    /// and setter inside the same statement would not be atomic.
    ///
    /// Examples that would not actually be atomic:
    ///
    ///     let atomicInt = Atomic(42)
    ///     // Calls getter and setter, but value may have been mutated in between
    ///     atomicInt.value += 1
    ///
    ///     let atomicArray = Atomic([1,2,3])
    ///     // Mutating the array through a subscript causes both a get and a set,
    ///     // acquiring and releasing the lock twice.
    ///     atomicArray[1] = 42
    ///
    /// See also: https://github.com/ReactiveCocoa/ReactiveSwift/issues/269
    public func mutate(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&_value)
        }
    }
}

extension Atomic: Equatable where A: Equatable {
    public static func ==(lhs: Atomic, rhs: Atomic) -> Bool {
        return lhs.atomic == rhs.atomic
    }
}

extension Atomic: Hashable where A: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(atomic)
    }
}
