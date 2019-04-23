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
import CoreLocation

public class OpenStreetGeocoderRequest: GeocoderRequest {
    
    // MARK: - Public Properties -
    
    /// Google API Key
    public var APIKey: String?
    
    // MARK: - Private Properties -
    
    /// JSON Operation
    private var jsonOperation: JSONOperation?
    
    // MARK: - Overriden Functions -
    
    public override func stop() {
        jsonOperation?.stop()
        super.stop()
    }
    
    public override func start() {
        guard state != .expired else {
            return
        }
        
        // Compose the request URL
        guard let url = composeURL() else {
            dispatch(data: .failure(.generic("Failed to compose valid request's URL.")))
            return
        }
        
        jsonOperation = JSONOperation(url, timeout: self.timeout?.interval)
        jsonOperation?.start { response in
            switch response {
            case .failure(let error):
                self.stop(reason: error, remove: true)
            case .success(let json):
                var places = [Place]()
                if let rawArray = json as? [Any] {
                    places = rawArray.compactMap { Place(openStreet: $0) }
                } else {
                    places.append(Place(openStreet: json))
                }
                self.value = places
                self.dispatch(data: .success(places), andComplete: true)
            }
        }
    }
    
    // MARK: - Private Helper Functions -
    
    private func composeURL() -> URL? {
        var urlComponents = URLComponents(url: baseURL(), resolvingAgainstBaseURL: false)
        
        var serverParams = [URLQueryItem]()
        serverParams.append(URLQueryItem(name: "format", value: "json"))
        serverParams.append(URLQueryItem(name: "addressdetails", value: "1"))

        switch operationType {
        case .geocoder:
            serverParams.append(URLQueryItem(name: "address", value: address!))
        case .reverseGeocoder:
            serverParams.append(URLQueryItem(name: "lat", value: "\(coordinates!.latitude)"))
            serverParams.append(URLQueryItem(name: "lon", value: "\(coordinates!.longitude)"))
        }
        
        serverParams += options?.serverParams() ?? []
        urlComponents?.queryItems = serverParams
        return urlComponents?.url
    }
    
    private func baseURL() -> URL {
        switch operationType {
        case .geocoder:
            return URL(string: "https://nominatim.openstreetmap.org/search/\(address!.urlEncoded)")!
        case .reverseGeocoder:
            return URL(string: "https://nominatim.openstreetmap.org/reverse")!
        }
    }

}
