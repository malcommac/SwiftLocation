//
//  SwiftLocationPlayground
//
//  Copyright (c) 2020 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import SwiftLocation
import CoreLocation

class GPSController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    // MARK: - IBOutlets

    @IBOutlet public var tableView: UITableView!
    
    // MARK: - Private Properties

    private var serviceOptions = GPSLocationOptions()
    private let settings: [RowSetting] = RowSetting.allCases

    // MARK: - Initialize
    
    public static func create() -> GPSController {
        let s = UIStoryboard(name: "GPSController", bundle: nil)
        return s.instantiateInitialViewController() as! GPSController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerUINibForClass(StandardCellSetting.self)
        tableView.registerUINibForClass(StandardCellButton.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        self.navigationItem.title = "GPS Location"
    }
    
    private func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settings.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == settings.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellButton.defaultReuseIdentifier, for: indexPath) as! StandardCellButton
            cell.onAction = { [weak self] in
                self?.createRequest()
            }
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier, for: indexPath) as! StandardCellSetting
        let item = settings[indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        
        switch item {
        case .accuracy:
            cell.valueLabel.text = serviceOptions.accuracy.description
        case .activityType:
            cell.valueLabel.text = serviceOptions.activityType.description
        case .minDistance:
            cell.valueLabel.text = (serviceOptions.minDistance == kCLDistanceFilterNone) ? NOT_SET : serviceOptions.minDistance.formattedValue
        case .minTimeInterval:
            cell.valueLabel.text = serviceOptions.minTimeInterval?.format() ?? NOT_SET
        case .subscription:
            cell.valueLabel.text = serviceOptions.subscription.description
        case .timeoutInterval:
            cell.valueLabel.text = serviceOptions.timeout?.description ?? NOT_SET
        case .precise:
            cell.valueLabel.text = serviceOptions.precise?.description ?? USER_SET
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = settings[indexPath.row]

        switch item {
        case .accuracy:         selectAccuracy()
        case .activityType:     selectActivityType()
        case .minDistance:      selectMinDistance()
        case .minTimeInterval:  selectMinInterval()
        case .subscription:     selectSubscriptionType()
        case .timeoutInterval:  selectTimeout()
        case .precise:          selectPrecise()
        }
        
    }
    
    // MARK: - Settings
    
    private func selectAccuracy() {
        let accuracyLevels: [UIAlertController.ActionSheetOption] = [
            GPSLocationOptions.Accuracy.any,
            GPSLocationOptions.Accuracy.city,
            GPSLocationOptions.Accuracy.neighborhood,
            GPSLocationOptions.Accuracy.block,
            GPSLocationOptions.Accuracy.house,
            GPSLocationOptions.Accuracy.room
        ].map { [weak self] item in
            (item.description, { _ in
                self?.serviceOptions.accuracy = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Accuracy",
                                          message: "Higher accuracy level may no return results depending the reachability of GPS satellities",
                                          options: accuracyLevels)
    }
    
    private func selectActivityType() {
        let accuracyLevels: [UIAlertController.ActionSheetOption] = [
            CLActivityType.other,
            CLActivityType.airborne,
            CLActivityType.automotiveNavigation,
            CLActivityType.fitness,
            CLActivityType.otherNavigation,
        ].map { [weak self] item in
            (item.description, { _ in
                self?.serviceOptions.activityType = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Activity Type",
                                          message: nil, options: accuracyLevels)
    }
    
    private func selectPrecise() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = [
            GPSLocationOptions.Precise.reducedAccuracy,
            GPSLocationOptions.Precise.fullAccuracy
        ].map { [weak self] item in
            (item.description, { _ in
                self?.serviceOptions.precise = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Precise Location", message: nil, options: subscriptionTypes)
    }
    
    private func selectMinDistance() {
        UIAlertController.showDoubleInput(title: "Select Minimum Distance", message: "Minimum horizontal distance to report new fresh data (meters)") { [weak self] value in
            self?.serviceOptions.minDistance = (value != nil ? CLLocationDistance(value!) : kCLDistanceFilterNone)
            self?.reloadData()
        }
    }
    
    private func selectMinInterval() {
        UIAlertController.showDoubleInput(title: "Select Minimum Interval", message: "Minimum interval to report new fresh data (seconds)") { [weak self] value in
            self?.serviceOptions.minTimeInterval = (value != nil ? TimeInterval(value!) : nil)
            self?.reloadData()
        }
    }
    
    private func selectSubscriptionType() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = [
            GPSLocationOptions.Subscription.single,
            GPSLocationOptions.Subscription.continous,
            GPSLocationOptions.Subscription.significant
        ].map { [weak self] item in
            (item.description, { _ in
                self?.serviceOptions.subscription = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Subscription", message: nil, options: subscriptionTypes)
    }
    
    private func selectTimeout() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = ([
            nil, -5, -10, 5, 10
        ] as [Int?]
        ).map { [weak self] item in
            let title = (item == nil ? "No Timeout" : (item! < 0 ? "Delayed \(abs(item!))s" : "Immediate \(item!)s"))
            return (title, { _ in
                if let value = item {
                    if value < 0 {
                        self?.serviceOptions.timeout = GPSLocationOptions.Timeout.delayed(TimeInterval(value))
                    } else {
                        self?.serviceOptions.timeout = GPSLocationOptions.Timeout.immediate(TimeInterval(value))
                    }
                } else {
                    self?.serviceOptions.timeout = nil
                }
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Subscription",
                                          message: "Delayed starts only after the necessary authorization will be granted",
                                          options: subscriptionTypes)
    }
    
    // MARK: - Helper

    private func createRequest() {
        let request = SwiftLocation.gpsLocationWith(serviceOptions)
        
        serviceOptions = GPSLocationOptions()
        serviceOptions.avoidRequestAuthorization = true
        reloadData()
        
        AppDelegate.attachSubscribersToGPS([request])
        
        UIAlertController.showAlert(title: "Request added successfully",
                                    message: "Updates will be available through notifications and inside the status panel for recurring requests.")
    }
    
}

// MARK: - RowSetting

extension GPSController {
    
    fileprivate enum RowSetting: CaseIterable {
        case subscription
        case timeoutInterval
        case accuracy
        case activityType
        case minDistance
        case minTimeInterval
        case precise

        var title: String {
            switch self {
            case .subscription:     return "Subscription Type"
            case .timeoutInterval:  return "Timeout Interval (s)"
            case .accuracy:         return "Accuracy Level"
            case .activityType:     return "Activity Type"
            case .minDistance:      return "Min Distance (mt)"
            case .minTimeInterval:  return "Min Time Interval (s)"
            case .precise:          return "Precise Location (iOS14+)"
            }
        }
        
        var subtitle: String {
            switch self {
            case .subscription:     return "How often update locations"
            case .timeoutInterval:  return "Time with no response before abort"
            case .accuracy:         return "High levels may fails depending GPS status"
            case .activityType:     return "Helps GPS to get better results"
            case .minDistance:      return "Min horizontal distance to report new data"
            case .minTimeInterval:  return "Min time interval to report new data"
            case .precise:          return "Require one time permission for precise updates"
            }
        }
        
    }
    
}
