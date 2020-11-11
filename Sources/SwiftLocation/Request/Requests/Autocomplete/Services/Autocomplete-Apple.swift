//
//  Autocomplete+Apple.swift
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
import MapKit

public extension Autocomplete {
    
    class Apple: NSObject, AutocompleteProtocol {
          
        /// Type of autocomplete operation
        public var operation: AutocompleteOp
        
        /// Is operation cancelled.
        public var isCancelled: Bool = false
        
        /// NOTE: This is not applicable to this service and value is ignored.
        public var timeout: TimeInterval?
        
        /// The region that defines the geographic scope of the search.
        /// Use this property to limit search results to the specified geographic area.
        /// The default value is nil which for `AppleOptions` means a region that spans the entire world.
        /// For other services when nil the entire parameter will be ignored.
        public var proximityRegion: MKCoordinateRegion?
                
        /// The types of search completions to include.
        /// By default all values are included `[.address, .pointOfInterest, .query]`.
        /// NOTE: `.pointOfInterest` is not available below iOS 13.
        public var resultType: Apple.ResultType = ResultType.all
        
        // MARK: - Private Properties
        
        /// Partial searcher.
        private var partialQuerySearcher: MKLocalSearchCompleter?
        private var fullQuerySearcher: MKLocalSearch?
        
        /// Callback to call at the end of the operation.
        private var callback: ((Result<[Autocomplete.Data], LocationError>) -> Void)?
        
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
        
        /// Initialize with request to get details for given result item.
        /// - Parameter resultItem: PartialAddressMatch.
        public init?(detailsFor resultItem: PartialAddressMatch?) {
            guard let id = resultItem?.id else {
                return nil
            }
            
            self.operation = .addressDetail(id)
            
            super.init()
        }
        
        // MARK: - Public Functions
        
        public func executeAutocompleter(_ completion: @escaping ((Result<[Autocomplete.Data], LocationError>) -> Void)) {
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
            
            resultType.applyToCompleter(partialQuerySearcher)
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


extension Autocomplete.Apple {
    
    public struct ResultType: OptionSet, CustomStringConvertible {
        public var rawValue: Int
        
        /// Value indicating that address completions should be included in results.
        public static let address = ResultType(rawValue: 1 << 0)
        
        // Value indicating that point of interest completions should be included in results.
        // NOTE: It will be ignored with iOS < 13
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        
        /// Value indicating that query completions should be included in results.
        public static let query = ResultType(rawValue: 1 << 2)
        
        public static let all : ResultType = [.address, .pointOfInterest, .query]
        
        public var allSelected: Bool {
            return self.rawValue == ResultType.all.rawValue
        }

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        fileprivate func applyToCompleter(_ completer: MKLocalSearchCompleter?) {
            guard let completer = completer else { return }
            
            if #available(iOS 13.0, *) {
                completer.resultTypes = resultTypes()
            } else {
                completer.filterType = filterTypes()
            }
        }
        
        @available(iOS 13.0, *)
        private func resultTypes() -> MKLocalSearchCompleter.ResultType {
            var value = MKLocalSearchCompleter.ResultType()
            if contains(.address) { value.insert(.address) }
            if contains(.pointOfInterest) { value.insert(.pointOfInterest) }
            if contains(.query) { value.insert(.query) }
            return value
        }
        
        private func filterTypes() -> MKLocalSearchCompleter.FilterType {
            if contains(.query) {
                return .locationsAndQueries
            } else {
                return .locationsOnly
            }
        }
        
        public var description: String {
            var options = [String]()
            if contains(.address) { options.append("address") }
            if contains(.pointOfInterest) { options.append("pointOfInterest") }
            if contains(.query) { options.append("query") }
            return options.joined(separator: ",")
        }
        
    }
    
}
