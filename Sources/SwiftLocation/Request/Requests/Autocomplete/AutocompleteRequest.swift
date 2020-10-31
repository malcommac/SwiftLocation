//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation

public class AutocompleteRequest: RequestProtocol, Codable {
    public typealias ProducedData = [Autocomplete.Data]
    
    /// Service used to perform the request.
    public let service: AutocompleteProtocol
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Readable name.
    public var name: String?
    
    /// Eviction policy of the request.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var evictionPolicy: Set<RequestEvictionPolicy> = [.onError, .onReceiveData(count: 1)]
    
    /// Subscribed callbacks.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// Is request enabled, by default is `true`.
    ///
    /// NOTE: You should never change it for this kind of request.
    public var isEnabled = true
    
    /// Last received value from the request's service.
    public var lastReceivedValue: (Result<[Autocomplete.Data], LocatorErrors>)?
    
    /// Number of data received. For this kind of request it's always 1 once data is arrived.
    public var countReceivedData = 0
    
    public var description: String {
        JSONStringify([
            "uuid": uuid,
            "name": name ?? "",
            "subscriptions": subscriptions.count,
            "enabled": isEnabled,
            "lastValue": lastReceivedValue?.description ?? "",
            "service": service.description
        ])
    }
    
    // MARK: - Public Properties
    
    public func validateData(_ data: [Autocomplete.Data]) -> DataDiscardReason? {
        return nil // performed by the service
    }
    
    public func startTimeoutIfNeeded() {
        // managed by the service
    }
    
    // MARK: - Initialization
    
    public init(_ service: AutocompleteProtocol) {
        self.service = service
    }
    
    // MARK: - Public Functions
        
    public static func == (lhs: AutocompleteRequest, rhs: AutocompleteRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public func didAddInQueue() {
        service.execute { [weak self] result in
            self?.dispatchData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case uuid, isEnabled, serviceKind, service, name
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(service.kind, forKey: .serviceKind)
        try container.encodeIfPresent(name, forKey: .name)
        
        switch service.kind {
        case .apple:    try container.encode((service as! Autocomplete.Apple), forKey: .service)
        case .google:   try container.encode((service as! Autocomplete.Google), forKey: .service)
        case .here:     try container.encode((service as! Autocomplete.Here), forKey: .service)
        }
    }
    
    // Decodable protocol
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        
        switch try container.decode(AutocompleteKind.self, forKey: .serviceKind) {
        case .apple:    self.service = try container.decode(Autocomplete.Apple.self, forKey: .service)
        case .google:   self.service = try container.decode(Autocomplete.Google.self, forKey: .service)
        case .here:     self.service = try container.decode(Autocomplete.Here.self, forKey: .service)
        }
    }

}

// MARK: - Result<[Autocomplete.Data],LocatorErrors>

public extension Result where Success == [Autocomplete.Data], Failure == LocatorErrors {
    
    var description: String {
        switch self {
        case .failure(let error):
            return "Failure \(error.localizedDescription)"
        case .success(let data):
            return "Success \(data.description)"
        }
    }
    
}
