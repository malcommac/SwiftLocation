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
    
    internal var completedRequests = [ServiceRequest]()
    
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        
        LocationManager.shared.onQueueChange.add({ added, request in
            if added == false {
                self.completedRequests.append(request)
            }
            self.reload()
        })
        
        LocationManager.shared.onAuthorizationChange.add({ _ in
            self.reload()
        })
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(createNewRequest))
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
        reload()
    }
    
    @objc func fireTimer() {
        reload()
    }
    
    @objc func createNewRequest() {
        //self.present(NewRequestController.create(), animated: true, completion: nil)
        let alert = UIAlertController(title: "New Request", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "GPS Location", style: .default, handler: { _ in
            self.present(NewGPSRequestController.create(), animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Location by IP", style: .default, handler: { _ in
            self.present(NewIPRequestController.create(), animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension RequestsMonitorController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6 // all kinds + completed requests
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = requestsForSection(section).count
        if section != 5 && count == 0 {
            return nil
        }
        switch section {
        case 0:
            return "\(count) GPS"
        case 1:
            return "\(count) IP LOCATION"
        case 2:
            return "\(count) GEOCODING"
        case 3:
            return "\(count) HEADING"
        case 4:
            return "\(count) AUTOCOMPLETE"
        case 5:
            return "COMPLETED REQUESTS"
        default:
            return nil
        }
    }
    
    private func requestsForSection(_ section: Int) -> [ServiceRequest] {
        switch section {
        case 0:
            return Array(locator.queueLocationRequests)
        case 1:
            return Array(locator.queueLocationByIPRequests)
        case 2:
            return Array(locator.queueGeocoderRequests)
        case 3:
            return Array(locator.queueHeadingRequests)
        case 4:
            return Array(locator.queueAutocompleteRequests)
        case 5:
            return completedRequests
        default:
            return []
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel!.font = UIFont.boldSystemFont(ofSize: 14.0)
            header.textLabel!.textColor = UIColor.darkGray
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestsForSection(section).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = requestsForSection(indexPath.section)[indexPath.row]
        
        switch request {
        case let locRequest as LocationRequest:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GPSRequestCell") as! GPSRequestCell
            cell.request = locRequest
            cell.monitorController = self
            return cell
            
        case let ipRequest as LocationByIPRequest:
            let cell = tableView.dequeueReusableCell(withIdentifier: "IPRequestCell") as! IPRequestCell
            cell.request = ipRequest
            cell.monitorController = self
            return cell
            
        default:
            fatalError("Not implemented")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let request = requestsForSection(indexPath.section)[indexPath.row]
        switch request {
        case _ as LocationRequest:
            return GPSRequestCell.height
       
        case _ as LocationByIPRequest:
            return IPRequestCell.height
            
        default:
            fatalError("Not implemented")
        }
    }
    
    public func reload() {
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
