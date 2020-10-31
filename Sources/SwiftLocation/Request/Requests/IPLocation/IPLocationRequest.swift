//
//  File.swift
//  
//
//  Created by daniele on 25/09/2020.
//

import Foundation

public class IPLocationRequest: RequestProtocol, Codable {
    public typealias ProducedData = IPLocation.Data
    
    // MARK: - Private Functions

    /// Service used to get the ip data.
    private var service: IPServiceProtocol
    
    // MARK: - Public Properties

    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy.
    /// NOTE: You don't need to change this value.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Callbacks subscribed.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is the requeste enabled.
    /// NOTE: You don't need to change this value.
    public var isEnabled = true
    
    /// Last received valid value.
    public var lastReceivedValue: (Result<IPLocation.Data, LocatorErrors>)? = nil
    
    /// Number of received data.
    /// NOTE: You don't need to change this value.
    public var countReceivedData = 0
    
    
    // MARK: - Public Functions
    
    public func validateData(_ data: IPLocation.Data) -> DataDiscardReason? {
        return nil // validation inside the service
    }
    
    public func startTimeoutIfNeeded() {
        // don't need for this request
    }
    
    public static func == (lhs: IPLocationRequest, rhs: IPLocationRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public init(_ service: IPServiceProtocol) {
        self.service = service
    }
    
    public func didAddInQueue() {
        // this kind of request starts once added to the queue pool.
        service.execute { [weak self] result in
            self?.receiveData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case uuid, isEnabled, service, serviceType, name
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(service.jsonServiceDecoder, forKey: .serviceType)
        try container.encodeIfPresent(name, forKey: .name)

        switch service.jsonServiceDecoder {
        case .ipapi:            try container.encode((service as! IPLocation.IPApi), forKey: .service)
        case .ipdata:           try container.encode((service as! IPLocation.IPData), forKey: .service)
        case .ipgeolocation:    try container.encode((service as! IPLocation.IPGeolocation), forKey: .service)
        case .ipify:            try container.encode((service as! IPLocation.IPify), forKey: .service)
        case .ipinfo:           try container.encode((service as! IPLocation.IPInfo), forKey: .service)
        case .ipstack:          try container.encode((service as! IPLocation.IPStack), forKey: .service)
        }
    }
    
    // Decodable protocol
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        let serviceType = try container.decode(IPServiceDecoders.self, forKey: .serviceType)
        
        switch serviceType {
        case .ipapi:            self.service = try container.decode(IPLocation.IPApi.self, forKey: .service)
        case .ipdata:           self.service = try container.decode(IPLocation.IPData.self, forKey: .service)
        case .ipgeolocation:    self.service = try container.decode(IPLocation.IPGeolocation.self, forKey: .service)
        case .ipify:            self.service = try container.decode(IPLocation.IPify.self, forKey: .service)
        case .ipinfo:           self.service = try container.decode(IPLocation.IPInfo.self, forKey: .service)
        case .ipstack:          self.service = try container.decode(IPLocation.IPStack.self, forKey: .service)
        }
    }
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "enabled": isEnabled,
            "lastValue": lastReceivedValue?.description ?? "",
            "subscriptions": subscriptions.count,
            "service": service.description
        ])
    }
    
}

// MARK: - Result<,LocatorErrors>

extension Result where Success == IPLocation.Data, Failure == LocatorErrors {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let data):
            return "Success \(data.description)"
        }
    }
    
}
