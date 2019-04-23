//
//  NewGeocodingRequestController.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import UIKit
import CoreLocation

public class NewGeocodingRequestController: UIViewController {
    
    @IBOutlet public var serviceButton: UIButton!
    @IBOutlet public var operationType: UIButton!
    @IBOutlet public var coordinatesLabel: UITextField!
    @IBOutlet public var addressLabel: UITextField!
    @IBOutlet public var apiKeyLabel: UITextField!

    private var service: GeocoderRequest.Service!
    private var isReverse: Bool = true
    
    public static func create() -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewGeocodingRequestController") as! NewGeocodingRequestController
        return UINavigationController(rootViewController: vc)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.service = .apple(GeocoderRequest.Options())
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didPressCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createRequest))
        
        reload()
    }
    
    @objc func didPressCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createRequest() {
        
        if self.service.requireAPIKey && self.apiKeyLabel.text?.isEmpty ?? true {
            showAlert(title: "Missing API Key", message: "This service require a valid API key to work.")
            return
        }
        
        switch isReverse {
        case true:
            guard let rawCoordinates = self.coordinatesLabel.text?.components(separatedBy: ","),
                rawCoordinates.count == 2 else {
                    showAlert(title: "Missing Coordinates", message: "Add coordinates in form of lat,lng")
                    return
            }
            let coordinates = CLLocationCoordinate2DMake(Double(rawCoordinates.first!)!, Double(rawCoordinates.last!)!)
            LocationManager.shared.locateFromCoordinates(coordinates, result: nil)
            
        case false:
            guard let address = self.addressLabel.text, address.isEmpty == false else {
                showAlert(title: "Missing Address", message: "Add address to geocode it.")
                return
            }
            LocationManager.shared.locateFromAddress(address, result: nil)
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction public func didChangeService() {
        let options: [SelectionItem<GeocoderRequest.Service>] = GeocoderRequest.Service.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        self.showPicker(title: "Select a Service", msg: nil, options: options, onSelect: { item in
            self.service = item.value!
            self.reload()
        })
    }
    
    @IBAction public func didChangeOperationMode() {
        let options: [SelectionItem<Bool>] = [
            SelectionItem(title: "From Location to Place (Reverse)", value: true),
            SelectionItem(title: "From Address to Place", value: false)
        ]
        self.showPicker(title: "Select a Mode", msg: nil, options: options, onSelect: { item in
            self.isReverse = item.value!
            self.reload()
        })
    }
    
    private func reload() {
        self.serviceButton.setTitle(self.service.description, for: .normal)
        self.apiKeyLabel.isEnabled = self.service.requireAPIKey
        self.addressLabel.isEnabled = self.isReverse == false
        self.coordinatesLabel.isEnabled = self.isReverse
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return
    }
}

