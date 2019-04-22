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

class RequestsMonitorController: UIViewController {
    
    public let locator = LocationManager.shared
    
    @IBOutlet public var table: UITableView!
    @IBOutlet public var preferredAuth: UIButton!
    @IBOutlet public var currentAuth: UILabel!
    @IBOutlet public var currentAccuracy: UILabel!
    @IBOutlet public var countLocationReqs: UILabel!
    @IBOutlet public var countLocationByIPReqs: UILabel!
    @IBOutlet public var countGeocodingReqs: UILabel!
    @IBOutlet public var countAutocompleteReqs: UILabel!
    @IBOutlet public var countHeadingReqs: UILabel!
    
    private var completedRequests = [ServiceRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        
        LocationManager.shared.onQueueChange.add({ _,_ in
            self.reload()
        })
        
        LocationManager.shared.onAuthorizationChange.add({ _ in
            self.reload()
        })
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(createNewRequest))
        
        reload()
    }
    
    @objc func createNewRequest() {
        self.present(NewRequestController.create(), animated: true, completion: nil)
    }
    
}

extension RequestsMonitorController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6 // all kinds + completed requests
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Locations via GPS"
        case 1: return "Locations via IP Address"
        case 2: return "Geocoding/Reverse Geocoding"
        case 3: return "Device Heading"
        case 4: return "Autocomplete"
        case 5: return "Completed Requests"
        default: return nil
        }
    }
    
    private func requestsForSection(_ section: Int) -> [ServiceRequest] {
        switch section {
        case 0:
            return Array(locator.queueLocationRequests)
        case 1:
            return Array(locator.queueLocationByIPRequests)
        case 3:
            return Array(locator.queueGeocoderRequests)
        case 4:
            return Array(locator.queueHeadingRequests)
        case 5:
            return Array(locator.queueAutocompleteRequests)
        case 6:
            return completedRequests
        default:
            return []
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestsForSection(section).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell") as! RequestCell
        cell.request = requestsForSection(indexPath.section)[indexPath.row]
        return cell
    }
    
    private func reload() {
        table.reloadData()
     
        countHeadingReqs.text = String(locator.queueHeadingRequests.count)
        countLocationReqs.text = String(locator.queueLocationRequests.count)
        countGeocodingReqs.text = String(locator.queueGeocoderRequests.count)
        countAutocompleteReqs.text = String(locator.queueAutocompleteRequests.count)
        countLocationByIPReqs.text = String(locator.queueLocationByIPRequests.count)
        currentAuth.text = LocationManager.state.description
        preferredAuth.setTitle(locator.preferredAuthorization.description, for: .normal)
        currentAccuracy.text = locator.accuracy?.description ?? "not in use"
    }
    
}

public class RequestCell: UITableViewCell {
    @IBOutlet public var stateLabel: UILabel!
    @IBOutlet public var requestTypeLabel: UILabel!
    @IBOutlet public var resultData: UILabel!
    @IBOutlet public var stopButton: UIButton!
    
    @IBAction public func didPressStop() {
        
    }
    
    public var request: ServiceRequest? {
        didSet {
            guard let request = request else {
                stateLabel.text = ""
                requestTypeLabel.text = ""
                resultData.text = ""
                stopButton.isEnabled = false
                return
            }
            
            stateLabel.text = request.state.description
            
            switch request {
            case let req as LocationRequest:
                requestTypeLabel.text = "GPS Loc \(req.accuracy.description)"
                
            case let req as LocationByIPRequest:
                requestTypeLabel.text = "IP Loc \(req.service.description)"

                
            default:
                break
            }
        }
    }
}
