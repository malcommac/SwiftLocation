//
//  IPAPICoRequest.swift
//  SwiftLocation
//
//  Created by dan on 19/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

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
                self.dispatch(data: .success(place))
            }
        }
    }
    
    public override func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        jsonOperation?.stop()
        super.stop(reason: reason, remove: remove)
    }
    
}
