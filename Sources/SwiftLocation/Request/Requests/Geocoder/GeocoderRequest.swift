//
//  File.swift
//  
//
//  Created by daniele on 27/09/2020.
//

import Foundation

public class GeocoderRequest: RequestProtocol, Codable {
    public typealias ProducedData = [GeoLocation]
    
    // MARK: - Public Properties
    
    /// Unique identifier of the request.
    public var uuid = UUID().uuidString
    
    /// Eviction policy for request. You should never change this for GeocoderRequest.
    public var evictionPolicy = Set<RequestEvictionPolicy>([.onError, .onReceiveData(count: 1)])
    
    /// Subscriptions which receive updates.
    public var subscriptions = [RequestDataCallback<DataCallback>]()
    
    /// This is ignored for this request.
    public var isEnabled = true
    
    /// This is ignored for this request.
    public var countReceivedData = 0
    
    /// Last received response.
    public var lastReceivedValue: (Result<[GeoLocation], LocatorErrors>)?

    // MARK: - Private Properties

    private var service: GeocoderServiceProtocol
    
    // MARK: - Public Functions
    
    public func validateData(_ data: [GeoLocation]) -> DataDiscardReason? {
        return nil
    }
    
    public func startTimeoutIfNeeded() {
        
    }
        
    public init(service: GeocoderServiceProtocol) {
        self.service = service
    }
    
    public func didAddInQueue() {
        service.execute { [weak self] result in
            self?.lastReceivedValue = result
            self?.dispatchData(result)
        }
    }
    
    public func didRemovedFromQueue() {
        service.cancel()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: GeocoderRequest, rhs: GeocoderRequest) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case uuid, isEnabled, serviceKind, service
    }
    
    // Encodable protocol
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(service.kind, forKey: .serviceKind)
        
        switch service.kind {
        case .apple:        try container.encode((service as! Geocoder.Apple), forKey: .service)
        case .google:       try container.encode((service as! Geocoder.Google), forKey: .service)
        case .here:         try container.encode((service as! Geocoder.Here), forKey: .service)
        case .mapBox:       try container.encode((service as! Geocoder.MapBox), forKey: .service)
        case .openStreet:   try container.encode((service as! Geocoder.OpenStreet), forKey: .service)
        }
    }
    
    // Decodable protocol
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        let serviceKind = try container.decode(GeocoderServiceKind.self, forKey: .serviceKind)
        
        switch serviceKind {
        case .apple:        self.service = try container.decode(Geocoder.Apple.self, forKey: .service)
        case .google:       self.service = try container.decode(Geocoder.Google.self, forKey: .service)
        case .here:         self.service = try container.decode(Geocoder.Here.self, forKey: .service)
        case .mapBox:       self.service = try container.decode(Geocoder.MapBox.self, forKey: .service)
        case .openStreet:   self.service = try container.decode(Geocoder.OpenStreet.self, forKey: .service)
        }
    }
        
}

