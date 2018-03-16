//
//  Mutex.swift
//  Hydra
//
//  Created by Daniele Margutti on 26/02/2018.
//  Copyright © 2018 Hydra. All rights reserved.
//

import Foundation
import Darwin

/// Mutex is a wrapper around pthread_mutex to keep the atomicity of a variable.
internal final class Mutex {
	
	/// Type of mutex behaviour.
	public enum Behaviour {
		case `default`
		case recursive
		
		public var mutex: pthread_mutex_t {
			var mutex: pthread_mutex_t = pthread_mutex_t()
			var attributes = pthread_mutexattr_t()
			guard pthread_mutexattr_init(&attributes) == 0 else {
				fatalError("Failed to create Mutex")
			}
			switch self {
			case .`default`:
				pthread_mutexattr_settype(&attributes, Int32(PTHREAD_MUTEX_NORMAL))
			case .recursive:
				pthread_mutexattr_settype(&attributes, Int32(PTHREAD_MUTEX_RECURSIVE))
			}
			guard pthread_mutex_init(&mutex, &attributes) == 0 else {
				fatalError("Failed to create Mutex")
			}
			pthread_mutexattr_destroy(&attributes)
			return mutex
		}
	}
	
	private var mutex: pthread_mutex_t
	
	public init(_ behaviour: Behaviour = .`default`) {
		self.mutex = behaviour.mutex
	}
	
	deinit {
		pthread_mutex_destroy(&mutex)
	}
	
	public func lock() {
		pthread_mutex_lock(&mutex)
	}
	
	public func tryLock() -> Bool {
		return pthread_mutex_trylock(&mutex) == 0
	}
	
	public func unlock() {
		pthread_mutex_unlock(&mutex)
	}
	
	public func sync<R>(execute job: () throws -> R) rethrows -> R {
		self.lock()
		defer { self.unlock() }
		return try job()
	}
	
	public func trySync<R>(execute job: () throws -> R) rethrows -> R? {
		guard self.tryLock() else { return nil }
		defer { self.unlock() }
		return try job()
	}
}
