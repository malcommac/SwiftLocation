//
//  File.swift
//  
//
//  Created by Rusty Zarse on 1/9/22.
//

import Foundation

public extension RequestProtocol {
    @available(iOS 13.0.0, *)
    func `async`(queue: DispatchQueue = .main) async throws -> ProducedData {
        return try await withCheckedThrowingContinuation { continuation in
            _ = then(queue: queue, continuation.resume)
        }
    }
}
