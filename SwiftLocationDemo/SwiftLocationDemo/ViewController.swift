//
//  ViewController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 24/09/2020.
//

import UIKit
import SwiftLocation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        /*Locator.shared.getLocation { options in
            options.request?.evictionPolicy = [.onReceiveData(count: 4)]
            options.accuracy = .city
        }.then(queue: .main) {
            switch $0 {
            case .failure(let error):
                print("🛑 One Shoot error: \(error.localizedDescription)")
            case .success(let data):
                print("✅ One Shoot: \(data.coordinate)")
            }
        }
        
        Locator.shared.getLocation {
            $0.subscription = .continous
            $0.accuracy = .room
            $0.timeout = .immediate(5)
        }.then(queue: .main) {
            switch $0 {
            case .failure(let error):
                print("🛑 Continous error: \(error.localizedDescription)")
            case .success(let data):
                print("✅ Continous: \(data.coordinate)")
            }
        }*/
        
        /*Locator.shared.getLocationByIP(IPStackService(APIKey: "")).then(queue: .main) { result in
            print(result)
        }*/
        
        Locator.shared.getLocationByIP(IPDataService(APIKey: "")).then(queue: .main) { result in
            print("result: \(result)")
        }
        
    }


}

