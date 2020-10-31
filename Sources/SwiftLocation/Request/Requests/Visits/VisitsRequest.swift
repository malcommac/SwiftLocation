//
//  File.swift
//  
//
//  Created by daniele margutti on 15/10/2020.
//

import Foundation
import CoreLocation

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
    public var lastReceivedValue: (Result<CLVisit, LocatorErrors>)? = nil

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

extension Result where Success == CLVisit, Failure == LocatorErrors {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let visit):
            return "Success \(visit.description)"
        }
    }
    
}
