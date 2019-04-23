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

public class IPAPICoRequest: LocationByIPRequest {
    
    private var jsonOperation: JSONOperation?
    
    public override var service: LocationByIPRequest.Service {
        return .ipApiCo
    }

    public override func start() {
        let url = URL(string: "https://ipapi.co/json")!
        self.jsonOperation = JSONOperation(url, timeout: self.timeout?.interval)
        self.jsonOperation?.start { response in
            switch response {
            case .failure(let error):
                self.stop(reason: error, remove: true)
                
            case .success(let json):
                let ip: String? = valueAtKeyPath(root: json, ["ip"])
                guard let _ = ip else {
                    self.stop(reason: .generic("General failure"), remove: true)
                    return
                }
                
                let place = IPPlace(ipAPICoJSON: json)
                self.value = place
                self.dispatch(data: .success(place), andComplete: true)
            }
        }
    }
    
    public override func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        jsonOperation?.stop()
        super.stop(reason: reason, remove: remove)
    }
    
}
