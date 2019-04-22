//
//  NewRequestController.swift
//  SwiftLocation
//
//  Created by dan on 22/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import UIKit

public class NewRequestController: UIViewController {
 
    @IBOutlet public var table: UITableView!

    public static func create() -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "NewRequestController") as! NewRequestController
        return UINavigationController(rootViewController: vc)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didPressCancel))
    }
    
    @objc func didPressCancel() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension NewRequestController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewGPSRequestCell") as! NewGPSRequestCell
            cell.parentVC = self
            return cell
            
        default:
            fatalError("Unknown")
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
}

public class NewRequestCell: UITableViewCell {

    public weak var parentVC: UIViewController?
    
    @IBAction public func createRequest() {
        
    }

}

public class NewGPSRequestCell: NewRequestCell {
    
    @IBOutlet public var timeoutButton: UIButton!
    @IBOutlet public var accuracyButton: UIButton!
    @IBOutlet public var modeButton: UIButton!
    
    private var timeout: Timeout.Mode? = nil {
        didSet {
            reload()
        }
    }
    
    private var accuracy: LocationManager.Accuracy = .city {
        didSet {
            reload()
        }
    }
    
    private var mode: LocationRequest.Subscription = .oneShot {
        didSet {
            reload()
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        self.timeout = .delayed(10)
        self.accuracy = .city
        self.mode = .oneShot
        reload()
    }
    
    @IBAction public func setMode() {
        let options: [SelectionItem<LocationRequest.Subscription>] = LocationRequest.Subscription.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        parentVC?.showPicker(title: "Select a Subscription mode",
                             msg: "One shot requests will be removed automatically once completed or after timeout interval is passed.",
                             options: options, onSelect: { item in
                                self.mode = item.value!
        })
    }
    
    @IBAction public func setAccuracy() {
        let options: [SelectionItem<LocationManager.Accuracy>] = LocationManager.Accuracy.all.map {
            return SelectionItem(title: $0.description, value: $0)
        }
        parentVC?.showPicker(title: "Select an Accuracy Level",
                             msg: "Request did not receive level lower than set accuracy level",
                             options: options, onSelect: { item in
            self.accuracy = item.value!
        })
    }
    
    @IBAction public func setTimeout() {
        let options: [SelectionItem<Timeout.Mode>] = [
            .init(title: "Absolute 5s", value: .absolute(5)),
            .init(title: "Absolute 10s", value: .absolute(10)),
            .init(title: "Absolute 20s", value: .absolute(20)),
            .init(title: "Delayed 5s", value: .delayed(5)),
            .init(title: "Delayed 10s", value: .delayed(10)),
            .init(title: "Delayed 20s", value: .delayed(20)),
            .init(title: "No Timeout", value: nil),
        ]
        parentVC?.showPicker(title: "Select a Timeout",
                             msg: "Delayed timer will start after user grant permission, absolute start immediately.",
                             options: options, onSelect: { item in
            self.timeout = item.value
        })
    }
    
    private func reload() {
        timeoutButton.setTitle(timeout?.description ?? "not set", for: .normal)
        accuracyButton.setTitle(accuracy.description, for: .normal)
        modeButton.setTitle(mode.description, for: .normal)
    }
    
    public override func createRequest() {
        LocationManager.shared.locateFromGPS(self.mode,
                                             accuracy: self.accuracy,
                                             timeout: self.timeout,
                                             result: nil)
        parentVC?.dismiss(animated: true, completion: nil)
    }
}

public class SelectionItem<Value> {
    public var title: String
    public var value: Value?
    
    public init(title: String, value: Value?) {
        self.title = title
        self.value = value
    }
}

extension UIViewController {
    
    public func showPicker<Value>(title: String, msg: String?,
                                  options: [SelectionItem<Value>], onSelect: @escaping ((SelectionItem<Value>) -> Void)) {
        let picker = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        
        for option in options {
            picker.addAction(UIAlertAction(title: option.title, style: .default, handler: { action in
                if let first = options.first(where: { action.title! == $0.title }) {
                    onSelect(first)
                }
            }))
        }
        
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(picker, animated: true, completion: nil)
    }
    
}
