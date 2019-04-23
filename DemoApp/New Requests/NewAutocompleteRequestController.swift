//
//  NewAutocompleteRequestController.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import Foundation
import UIKit

public class NewAutocompleteRequestController: UIViewController {
    
    @IBOutlet public var serviceButton: UIButton!
    @IBOutlet public var operationType: UIButton!
    @IBOutlet public var apiKey: UITextField!
    @IBOutlet public var searchField: UITextField!
    @IBOutlet public var searchFieldLabel: UILabel!

    private var service: AutoCompleteRequest.Service!
    private var operation: AutoCompleteRequest.Operation!

    public static func create() -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewAutocompleteRequestController") as! NewAutocompleteRequestController
        return UINavigationController(rootViewController: vc)
    }
    
    @IBAction public func didChangeService() {
        let options: [SelectionItem<AutoCompleteRequest.Service>] = AutoCompleteRequest.Service.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        self.showPicker(title: "Select a Service", msg: nil, options: options, onSelect: { item in
            self.service = item.value!
            self.reload()
        })
    }
    
    @IBAction public func didChangeOperation() {
        let options: [SelectionItem<AutoCompleteRequest.Operation>] = AutoCompleteRequest.Operation.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        self.showPicker(title: "Select an Operation", msg: nil, options: options, onSelect: { item in
            self.operation = item.value!
            self.reload()
        })
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.service = .apple(nil)
        self.operation = .partialSearch("")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didPressCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createRequest))
        
        reload()
    }
    
    @objc func didPressCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createRequest() {
        var serviceToUse: AutoCompleteRequest.Service!
        switch self.service! {
        case .apple:
            serviceToUse = .apple(AutoCompleteRequest.Options())
        case .google:
            serviceToUse = .google(AutoCompleteRequest.GoogleOptions(APIKey: self.apiKey.text))
        }
        
        switch operation! {
        case .partialSearch(_):
            LocationManager.shared.autocomplete(partialMatch: .partialSearch(searchField.text ?? ""),
                                                service: serviceToUse, result: nil)
        case .placeDetail(_):
            LocationManager.shared.autocomplete(partialMatch: .placeDetail(searchField.text ?? ""), service: serviceToUse, result: nil)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func reload() {
        self.serviceButton.setTitle(self.service.description, for: .normal)
        self.operationType.setTitle(self.operation.description, for: .normal)
        
        switch self.operation! {
        case .partialSearch:
            self.searchFieldLabel.text = "Partial String:"
        case .placeDetail:
            self.searchFieldLabel.text = "Place ID/Full String:"
        }
    }
}
