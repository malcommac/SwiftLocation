//
//  File.swift
//  
//
//  Created by daniele on 28/09/2020.
//

import Foundation
import CoreLocation
import MapKit

public extension Autocomplete {
    
    class Apple: NSObject, AutocompleteProtocol {
        
        public private(set) var kind: AutocompleteKind = .apple
        
        /// Is operation cancelled.
        public var isCancelled: Bool = false
        
        /// The region that defines the geographic scope of the search.
        /// Use this property to limit search results to the specified geographic area.
        /// The default value is nil which for `AppleOptions` means a region that spans the entire world.
        /// For other services when nil the entire parameter will be ignored.
        public var proximityRegion: MKCoordinateRegion?
        
        // Use this property to determine whether you want completions that represent points-of-interest
        // or whether completions might yield additional relevant query strings.
        // The default value is set to `.locationAndQueries`:
        // Points of interest and query suggestions.
        /// Specify this value when you want both map-based points of interest and common
        /// query terms used to find locations. For example, the search string “cof” yields a completion for “coffee”.
        public var dataFilter: MKLocalSearchCompleter.FilterType = .locationsAndQueries
        
        // MARK: - Private Properties
        
        /// Type of autocomplete operation
        private let operation: AutocompleteOp
        
        /// Partial searcher.
        private var partialQuerySearcher: MKLocalSearchCompleter?
        private var fullQuerySearcher: MKLocalSearch?
        
        /// Callback to call at the end of the operation.
        private var callback: ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)?
        
        // MARK: - Initialization
        
        /// Search for matches of a partial search address.
        /// Returned values is an array of `Autocomplete.AutocompleteResult.partial`.
        ///
        /// - Parameters:
        ///   - partialMatch: partial match of the address.
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(partialMatches partialAddress: String, region: MKCoordinateRegion? = nil) {
            self.operation = .partialMatch(partialAddress)
            self.proximityRegion = region
            
            super.init()
        }
        
        /// You can use this method when you have a full address and you want to get the details.
        ///
        /// - Parameter addressDetail: full address
        
        /// If you want to get the details of a partial search result obtained from `init(partialMatches:region)` call, you
        /// can use this method passing the full address.
        ///
        /// - Parameters:
        ///   - fullAddress: full address to search
        ///   - region: Use this property to limit search results to the specified geographic area.
        public init(detailsFor fullAddress: String, region: MKCoordinateRegion? = nil) {
            self.operation = .addressDetail(fullAddress)
            self.proximityRegion = region
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func execute(_ completion: @escaping ((Result<[Autocomplete.Data], LocatorErrors>) -> Void)) {
            self.callback = completion
            
            switch operation {
            case .partialMatch(let partialAddress):
                executePartialAddress(partialAddress)
            case .addressDetail(let fullAddress):
                executeAddressDetail(fullAddress)
            }
        }
        
        public func cancel() {
            isCancelled = true
            
            switch operation {
            case .partialMatch:
                partialQuerySearcher?.cancel()
                partialQuerySearcher = nil
                
            case .addressDetail:
                fullQuerySearcher?.cancel()
                fullQuerySearcher = nil
            }
        }
        
        // MARK: - Private Functions
        
        private func executePartialAddress(_ partialAddress: String) {
            partialQuerySearcher = MKLocalSearchCompleter()
            partialQuerySearcher?.queryFragment = partialAddress
            if let proximityRegion = self.proximityRegion {
                partialQuerySearcher?.region = proximityRegion
            }
            partialQuerySearcher?.filterType = dataFilter
            partialQuerySearcher?.delegate = self
        }
        
        private func executeAddressDetail(_ fullAddress: String) {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = fullAddress
            if let proximityRegion = self.proximityRegion { // otherwise it will be a region which spans the entire world.
                request.region = proximityRegion
            }
            
            fullQuerySearcher = MKLocalSearch(request: request)
            fullQuerySearcher?.start(completionHandler: { [weak self] (response, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.callback?(.failure(.other(error.localizedDescription)))
                    return
                }
                
                let places = GeoLocation.fromAppleList(response?.mapItems)
                self.callback?(.success(places))
            })
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case proximityRegionCenter, proximityRegionSpan, dataFilter, operation
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(proximityRegion?.center, forKey: .proximityRegionCenter)
            try container.encodeIfPresent(proximityRegion?.span, forKey: .proximityRegionSpan)
            try container.encode(dataFilter.rawValue, forKey: .dataFilter)
            try container.encode(operation, forKey: .operation)
        }
        
        // Decodable protocol
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let proximityCenter = try container.decodeIfPresent(CLLocationCoordinate2D.self, forKey: .proximityRegionCenter),
               let proximitySpan = try container.decodeIfPresent(MKCoordinateSpan.self, forKey: .proximityRegionSpan) {
                self.proximityRegion = MKCoordinateRegion(center: proximityCenter, span: proximitySpan)
            }
            
            self.dataFilter = try MKLocalSearchCompleter.FilterType(rawValue: container.decode(Int.self, forKey: .dataFilter))!
            self.operation = try container.decode(AutocompleteOp.self, forKey: .operation)
        }
        
    }
    
}

// MARK: - Autocomplete.Apple - MKLocalSearchCompleterDelegate

extension Autocomplete.Apple: MKLocalSearchCompleterDelegate {
    
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        cancel()
        
        let addressMatches = PartialAddressMatch.fromAppleList(completer)
        callback?(.success(addressMatches))
    }
    
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        callback?(.failure(.other(error.localizedDescription)))
    }
    
}
