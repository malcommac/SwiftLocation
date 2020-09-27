//
//  ViewController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 24/09/2020.
//

import UIKit
import SwiftLocation
import CoreLocation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        /*Locator.shared.getGPSLocation { options in
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
        
        Locator.shared.getGPSLocation {
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
        
        /*Locator.shared.getIPLocation(IPStackService(APIKey: "")).then(queue: .main) { result in
            print(result)
        }*/
        
        /*Locator.shared.getIPLocation(IPDataService(APIKey: "")).then(queue: .main) { result in
            print("result: \(result)")
        }*/
        
        /*Locator.shared.getIPLocation(IPInfoService(APIKey: "1c61f98ad7a104")).then(queue: .main) { result in
            print("\(result)")
        }*/
        
       /* Locator.shared.getIPLocation(IPAPIService()).then(queue: .main) { result in
            print(result)
        }*/
        
        /*Locator.shared.getIPLocation(IPGeolocationService(targetIP: "2.236.174.49", APIKey: "e618c7ed650d43d2b59f6390b65f7349")).then(queue: .main) { result in
            print("\(result)")
        }*/
        
        /*Locator.shared.getIPLocation(IPIpifyService(APIKey: "")).then(queue: .main) { result in
            print("\(result)")
        }*/
        

       /* Locator.shared.getGeocode(AppleGeocoderService(address: "via veneto 12, rieti")).then(queue: .main) { result in
            print(result)
        }*/
        
        /*Locator.shared.getGeocode(AppleGeocoderService(coordinates: CLLocationCoordinate2D(latitude: 42.4333871, longitude: 12.92514))).then(queue: .main) { result in
            print(result)
        }*/
        
        /*Locator.shared.getGeocode(GoogleGeocoderService(address: "Empire State Building", APIKey: "")).then(queue: .main) { result in
            print(result)
        }*/
        
        /*Locator.shared.getGeocode(GoogleGeocoderService(coordinates: CLLocationCoordinate2D(latitude: 40.748441, longitude: -73.985428), APIKey: "")).then(queue: .main) { result in
            print(result)
        }*/
        
        Locator.shared.getGeocode(OpenStreetGeocoderService(address: "Via Veneto 12, Rieti")).then(queue: .main) { result in
            print(result)
        }
        
    }


}

