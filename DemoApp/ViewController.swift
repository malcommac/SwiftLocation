//
//  ViewController.swift
//  DemoApp
//
//  Created by dan on 14/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        LocationManager.shared.preferredAuthorization = .whenInUse
        /*let request = LocationManager.shared.locate(fromGPS: .continous, accuracy: .city, result: { result in
            switch result {
            case .success(let location):
                print("Location: \(location)")
            case .failure(let error):
                print("Error: \(error)")
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            request.stop()
        }*/
        
//        let request = LocationManager.shared.locate(fromAddress: "Via Dei Durantini 221, Roma") { data in
//            switch data {
//            case .success(let place):
//                print("Place: \(place)")
//            case .failure(let error):
//                print("Error: \(error)")
//            }
//        }
        
        //let options = GeocoderRequest.GoogleOptions()
        //options.apiKey = "AIzaSyBFNt-SA_YWs6avChK-sU5aMR3o7DRTH-8"
       /* let options = GeocoderRequest.OpenStreetOptions()
        
//        let r = LocationManager.shared.locate(fromAddress: "Via Di Santa Prassede 24, Roma", service: google) { data in
//            print("")
//        }

        let coordinates = CLLocationCoordinate2D(latitude: 41.901206, longitude: 12.498941)
        let r = LocationManager.shared.locate(fromCoordinates: coordinates, timeout: nil, service: .openStreet(options)) { data in
            switch data {
            case .failure(let error):
                print("Errore: \(error)")
            case .success(let places):
                print("\(places.count) places")
            }
        }*/
        
       /* var options = AutoCompleteRequest.GoogleOptions()
        options.APIKey = "AIzaSyBFNt-SA_YWs6avChK-sU5aMR3o7DRTH-8"

       /* var options = AutoCompleteRequest.AppleOptions()
        options.region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(41.884641, 12.488470),
                                            latitudinalMeters: 20000, longitudinalMeters: 20000)
        options.partialMatchSearch = false
        */
        let op: AutoCompleteRequest.Operation = .placeDetail("ChIJz7XYDsNjLxMRjpoWIKhIJCw")
        let r = LocationManager.shared.autocomplete(partialMatch: op, service: .google(options)) { data in
            switch data {
            case .failure(let error):
                print("Errore: \(error)")
            case .success(let places):
                print("\(places.count) places")
            }
        }
        */
        
        LocationManager.shared.locateFromIP(service: .ipApiCo) { data in
            switch data {
            case .failure(let error):
                print("")
            case .success(let data):
                print("")
            }
        }
        
    }
    
    
}

