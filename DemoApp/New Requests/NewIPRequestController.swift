//
//  NewIPRequestController.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import UIKit

public class NewIPRequestController: UIViewController {
    
    @IBOutlet public var serviceButton: UIButton!
    
    private var service: LocationByIPRequest.Service!
    
    public static func create() -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewIPRequestController") as! NewIPRequestController
        return UINavigationController(rootViewController: vc)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.service = .ipAPI
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didPressCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createRequest))
        
        reload()
    }
    
    @objc func didPressCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createRequest() {
        LocationManager.shared.locateFromIP(service: self.service, result: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction public func didChangeService() {
        let options: [SelectionItem<LocationByIPRequest.Service>] = LocationByIPRequest.Service.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        self.showPicker(title: "Select a Service", msg: nil, options: options, onSelect: { item in
            self.service = item.value!
            self.reload()
        })
    }
    
    private func reload() {
        self.serviceButton.setTitle(self.service.description, for: .normal)
    }
    
}

