//
//  VisitsRequest.swift
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
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

/// This is the request class to monitor significant visits.
public class VisitsRequest: RequestProtocol, Codable {
    public typealias ProducedData = CLVisit
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy of the request.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError]
    
    /// Subscribed callbacks.
    public var subscriptions = [RequestDataCallback<DataCallback>]()

    /// Is request enabled, by default is `true`.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var isEnabled = true
    
    /// To help the system determine when to pause updates, you must also assign an appropriate value to the activityType property of your location manager.
    public let activityType: CLActivityType
    
    /// Last received value from the request's service.
    public var lastReceivedValue: (Result<CLVisit, LocationError>)? = nil

    /// Number of data received. For this kind of request it's always 1 once data is arrived.
    public var countReceivedData = 0
    
    public static func == (lhs: VisitsRequest, rhs: VisitsRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, activityType, name
    }
    
    /// Initialize a new request to monitor visits.
    /// The visits service is the most power-efficient way of gathering location data.
    ///
    /// - Parameter activityType: To help the system determine when to pause updates,
    ///                           you must also assign an appropriate value to the activityType
    ///                           property of your location manager (by default is `.other`)
    public init(activityType: CLActivityType) {
        self.activityType = activityType
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(activityType.rawValue, forKey: .activityType)
        try container.encodeIfPresent(name, forKey: .name)
    }
    
    // Decodable protocol
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.activityType = try CLActivityType(rawValue: container.decode(Int.self, forKey: .activityType))!
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public func startTimeoutIfNeeded() {
        
    }
    
    public func validateData(_ data: CLVisit) -> DataDiscardReason? {
        nil
    }
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "enabled" : isEnabled,
            "activity" : activityType.description,
            "lastValue" : lastReceivedValue?.description ?? ""
        ])
    }
    
}

// MARK: Result<CLVisit,LocatorErrors>

public extension Result where Success == CLVisit, Failure == LocationError {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let visit):
            return "Success \(visit.description)"
        }
    }
    
    var error: LocationError? {
        switch self {
        case .failure(let e): return e
        case .success: return nil
        }
    }
    
    var data: CLVisit? {
        switch self {
        case .failure: return nil
        case .success(let v): return v
        }
    }
    
}
