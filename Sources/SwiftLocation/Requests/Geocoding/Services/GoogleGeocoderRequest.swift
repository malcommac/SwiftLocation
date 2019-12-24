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

public class GoogleGeocoderRequest: GeocoderRequest {
        
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
                
                let status: String? = valueAtKeyPath(root: json, ["status"])
                if status != "OK",
                    let errorMsg: String = valueAtKeyPath(root: json, ["error_message"]), !errorMsg.isEmpty {
                    self.stop(reason: .generic(errorMsg), remove: true)
                    return
                }
                
                let rawPlaces: [Any]? = valueAtKeyPath(root: json, ["results"])
                let places = rawPlaces?.compactMap({ Place(googleJSON: $0) }) ?? []
                self.value = places
                self.dispatch(data: .success(places), andComplete: true)
            }
        }
    }
    
    // MARK: - Private Helper Functions -
    
    private func composeURL() -> URL? {
        guard let APIKey = (options as? GoogleOptions)?.APIKey else {
            dispatch(data: .failure(.missingAPIKey))
            return nil
        }
        
        var urlComponents = URLComponents(url: baseURL(), resolvingAgainstBaseURL: false)
        
        var serverParams = [URLQueryItem]()
        serverParams.append(URLQueryItem(name: "key", value: APIKey)) // google api key

        switch operationType {
        case .geocoder:
            serverParams.append(URLQueryItem(name: "address", value: address!))
        case .reverseGeocoder:
            serverParams.append(URLQueryItem(name: "latlng", value: "\(coordinates!.latitude),\(coordinates!.longitude)"))
        }
        
        serverParams += options?.serverParams() ?? []
        urlComponents?.queryItems = serverParams
        return urlComponents?.url
    }
    
    private func baseURL() -> URL {
        switch operationType {
        case .geocoder:
            return URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
        case .reverseGeocoder:
            return URL(string: "https://maps.googleapis.com/maps/api/geocode/json")!
        }
    }

}
