//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation
import MapKit
import CoreLocation

public class AppleAutoCompleteRequest: AutoCompleteRequest {
    
    private var partialQuerySearcher: MKLocalSearchCompleter?
    private var fullQuerySearcher: MKLocalSearch?

    // MARK: - Overridden Methods -
    
    public override func start() {
        guard state != .expired, let options = options else {
            return
        }
        
        switch options.operation {
        case .partialSearch:
            searchForPartialSearchAutocomplete(options: options)
        case .placeDetail:
            searchForPlaceDetailAutocomplete(options: options)
        }
    }
    
    public override func stop() {
        partialQuerySearcher?.cancel()
        super.stop()
    }
    
    // MARK: - Private Helper Methods -
    
    private func searchForPartialSearchAutocomplete(options: Options) {
        partialQuerySearcher = MKLocalSearchCompleter()
        partialQuerySearcher?.queryFragment = options.operation.value
        if let region = options.region { // otherwise it will be a region which spans the entire world.
            partialQuerySearcher?.region = region
        }
        partialQuerySearcher?.filterType = options.filter
        partialQuerySearcher?.delegate = self
    }
    
    private func searchForPlaceDetailAutocomplete(options: Options) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = options.operation.value
        if let region = options.region { // otherwise it will be a region which spans the entire world.
            request.region = region
        }
        fullQuerySearcher = MKLocalSearch(request: request)
        fullQuerySearcher?.start(completionHandler: { (response, error) in
            if let error = error {
                self.stop(reason: .generic(error.localizedDescription), remove: true)
                return
            }
            
            let places: [PlaceMatch] = response?.mapItems.map {
                let place = Place(mapItem: $0)
                return .fullMatch(place)
            } ?? []
            self.value = places
            self.dispatch(data: .success(places), andComplete: true)
        })
    }
    
}

extension AppleAutoCompleteRequest: MKLocalSearchCompleterDelegate {
    
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        partialQuerySearcher?.cancel()
        let places: [PlaceMatch] = completer.results.map {
            let place = PlacePartialMatch(localSearchCompletion: $0)
            return PlaceMatch.partialMatch(place)
        }
        value = places
        dispatch(data: .success(places), andComplete: true)
    }
    
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        stop(reason: .generic(error.localizedDescription), remove: true)
    }
    
}
