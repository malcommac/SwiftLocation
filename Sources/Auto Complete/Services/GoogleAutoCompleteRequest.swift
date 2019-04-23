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

public class GoogleAutoCompleteRequest: AutoCompleteRequest {
    
        // MARK: - Private Properties -
    
    /// JSON Operation
    private var jsonOperation: JSONOperation?
    
    // MARK: - Public Functions -
    
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

                // Validate google response
                let status: String? = valueAtKeyPath(root: json, ["status"])
                if status != "OK",
                    let errorMsg: String = valueAtKeyPath(root: json, ["error_message"]), !errorMsg.isEmpty {
                    self.stop(reason: .generic(errorMsg), remove: true)
                    return
                }
                
                switch self.options!.operation {
                case .partialSearch:
                    let places = self.parsePartialMatchJSON(json)
                    self.dispatch(data: .success(places), andComplete: true)
                case .placeDetail:
                    var places = [PlaceMatch]()
                    if let resultNode: Any = valueAtKeyPath(root: json, ["result"]) {
                        let place = Place(googleJSON: resultNode)
                        places.append(.fullMatch(place))
                    }
                    self.value = places
                    self.dispatch(data: .success(places), andComplete: true)
                }
            }
        }
    }
    
    // MARK: - Private Helper Functions -

    private func parsePartialMatchJSON(_ json: Any) -> [PlaceMatch] {
        let rawList: [Any]? = valueAtKeyPath(root: json, ["predictions"])
        let list: [PlaceMatch]? = rawList?.map({ rawItem in
            let place = PlacePartialMatch(googleJSON: rawItem)
            return PlaceMatch.partialMatch(place)
        })
        return list ?? []
    }
    
    private func composeURL() -> URL? {
        guard let APIKey = (options as? GoogleOptions)?.APIKey else {
            dispatch(data: .failure(.missingAPIKey))
            return nil
        }

        var serverParams = [URLQueryItem]()

        var baseURL: URL!
        switch options!.operation {
        case .partialSearch:
            baseURL = URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
            serverParams.append(URLQueryItem(name: "input", value: options!.operation.value))

        case .placeDetail:
            baseURL = URL(string: "https://maps.googleapis.com/maps/api/place/details/json")!
            serverParams.append(URLQueryItem(name: "placeid", value: options!.operation.value))
            
        }
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        
        serverParams.append(URLQueryItem(name: "key", value: APIKey)) // google api key
        serverParams += (options?.serverParams() ?? [])
        urlComponents?.queryItems = serverParams
        return urlComponents?.url
    }

}
