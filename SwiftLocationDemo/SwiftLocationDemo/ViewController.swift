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
        
        /*Locator.shared.getGeocode(OpenStreetGeocoderService(address: "Via Veneto 12, Rieti")).then(queue: .main) { result in
            print(result)
        }*/
        
       /* Locator.shared.getAutocomplete(AppleAutocomplete(partialMatches: "via veneto")).then(queue: .main) { result in
            print(result)
        }
        
                
        Locator.shared.getAutocomplete(AppleAutocomplete(detailsFor: "Via Veneto 12, Rieti")).then(queue: .main) { result in
            print(result)
        }*/
        
       /* Locator.shared.getAutocomplete(GoogleAutocomplete(partialMatches: "Via veneto rieti", APIKey: "" )).then(queue: .main) { result in
            print(result)
        }*/
        
        /*
        Locator.shared.getAutocomplete(GoogleAutocomplete(detailsFor: "EitWaWEgVmVuZXRvLCBSaWV0aSwgUHJvdmluY2Ugb2YgUmlldGksIEl0YWx5Ii4qLAoUChIJnzTT0cisLxMRreCrDTlsp8gSFAoSCT8z3roIqy8TEZHBUuEuiGbj", APIKey: "")).then(queue: .main) { result in
            print(result)
        }*/
        
        /*
        let c = CLLocationCoordinate2D(latitude: 41.901026, longitude: 12.499178)
        var mapBox = MapBoxGeocoderService(coordinates: c, APIKey: "")
        Locator.shared.getGeocode(mapBox).then(queue: .main) { result in
            print(result)
        }*/
        
        /*let mapBox = MapBoxGeocoderService(address: "Via veneto", APIKey: "")
        Locator.shared.getGeocode(mapBox).then(queue: .main) { result in
            print(result)
        }*/
        
        /*let c = CLLocationCoordinate2D(latitude: 37.4267861, longitude: -122.0806032)
        let hereMaps = HereGeocoderService(coordinates: c, APIKey: "")
        Locator.shared.getGeocode(hereMaps).then(queue: .main) { result in
            print(result)
        }*/
        
        /*
        let coords = CLLocationCoordinate2D(latitude: 42.42277, longitude: 12.91436)
        let hereMaps = HereAutocomplete(partialMatches: "via veneto",
                                        limit: .proximity(coords),
                                        APIKey: "HvPrS_nFVuIywo1PneI-9KcXH9ZjUA3q-b0-ENA8xkw")
        Locator.shared.getAutocomplete(hereMaps).then(queue: .main) { result in
            print(result)
        }*/
        
        /*let hereMaps = HereAutocomplete(detailsFor: "Via Veneto, Via Vittorio Veneto, 00187 Roma RM, Italia",
                                        APIKey: "HvPrS_nFVuIywo1PneI-9KcXH9ZjUA3q-b0-ENA8xkw")
        Locator.shared.getAutocomplete(hereMaps).then(queue: .main) { result in
            print(result)
        }*/
    
        /*let hereMaps = HereAutocomplete(lookupByID: "here:pds:place:380sr2yk-b7b98fe7321b4e77ad06668c861c01b5",
                                        APIKey: "G1DzMylAa0jm4GbKAU5IIku50TjVbyU4EapclLAPBEA")
        Locator.shared.getAutocomplete(hereMaps).then(queue: .main) { result in
            print(result)
        }*/
        
    }


}

