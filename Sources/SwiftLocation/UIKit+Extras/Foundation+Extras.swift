//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

// MARK: - Array

internal extension Array {
    
    mutating func appendIfNotNil(_ element: Element?) {
        guard let element = element else { return }
        append(element)
    }
    
    mutating func appendIfNotNils(_ elements: [Element?]) {
        elements.forEach {
            appendIfNotNil($0)
        }
    }
    
}

// MARK: - URLQueryItem

internal extension URLQueryItem {
    
    init?(name: String, optional value: String?) {
        guard let value = value else { return nil }
        self.init(name: name, value: value)
    }
    
}

// MARK: - Dictionary

extension Dictionary {
    
    mutating internal func setValue(value: Any, forKeyPath keyPath: String) {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            debugPrint("Unable to use string as key on type: \(Key.self)"); return
        }
        keys.remove(at: 0)
        if keys.isEmpty, let settable = value as? Value {
            self[first] = settable
        } else {
            let rejoined = keys.joined(separator: ".")
            var subdict: [NSObject : AnyObject] = [:]
            if let sub = self[first] as? [NSObject : AnyObject] {
                subdict = sub
            }
            subdict.setValue(value: value, forKeyPath: rejoined)
            if let settable = subdict as? Value {
                self[first] = settable
            } else {
                debugPrint("Unable to set value: \(subdict) to dictionary of type: \(type(of: self))")
            }
        }
        
    }
    
    internal func valueForKeyPath<T>(keyPath: String) -> T? {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            debugPrint("Unable to use string as key on type: \(Key.self)")
            return nil
        }
        
        guard let value = self[first] else {
            return nil
        }
        
        keys.remove(at: 0)
        if !keys.isEmpty, let subDict = value as? [NSObject : AnyObject] {
            let rejoined = keys.joined(separator: ".")
            
            return subDict.valueForKeyPath(keyPath: rejoined)
        }
        return value as? T
    }
    
}

// MARK: - String

internal extension String {
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
    
}
