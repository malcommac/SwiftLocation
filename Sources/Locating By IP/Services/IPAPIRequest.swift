//
//  IPAPIRequest.swift
//  SwiftLocation
//
//  Created by dan on 19/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

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
                self.dispatch(data: .success(place))
            }
        }
    }
    
    public override func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        jsonOperation?.stop()
        super.stop(reason: reason, remove: remove)
    }
    
}
