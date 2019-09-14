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

public class IPAPIRequest: LocationByIPRequest {

    private var jsonOperation: JSONOperation?
    
    public override var service: LocationByIPRequest.Service {
        return .ipAPI
    }
    
    public override func start() {
        let url = URL(string: "http://ip-api.com/json/")!
        self.jsonOperation = JSONOperation(url, timeout: self.timeout?.interval)
        self.jsonOperation?.start { response in
            switch response {
            case .failure(let error):
                self.stop(reason: error, remove: true)
                
            case .success(let json):
                let status: String? = valueAtKeyPath(root: json, ["status"])
                guard status == "success" else {
                    self.stop(reason: .generic("General failure"), remove: true)
                    return
                }
                
                let place = IPPlace(ipAPIJSON: json)
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
