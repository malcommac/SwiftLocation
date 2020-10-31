//
//  GPSController.swift
//  SwiftLocationDemo
//
//  Created by daniele margutti on 16/10/2020.
//

import UIKit
import SwiftLocation
import CoreLocation

fileprivate enum GPSSection: CaseIterable {
    case subscription
    case timeoutInterval
    case accuracy
    case activityType
    case minDistance
    case minTimeInterval
    
    var title: String {
        switch self {
        case .subscription:
            return "Subscription Type"
        case .timeoutInterval:
            return "Timeout Interval"
        case .accuracy:
            return "Accuracy"
        case .activityType:
            return "Activity Type"
        case .minDistance:
            return "Min Distance"
        case .minTimeInterval:
            return "Min Time Interval"
        }
    }
    
    var subtitle: String {
        switch self {
        case .subscription:
            return "How often update locations"
        case .timeoutInterval:
            return "Time with no response before abort"
        case .accuracy:
            return "High levels may lead to timeout in some cases"
        case .activityType:
            return "Helps GPS  to get better  result"
        case .minDistance:
            return "Min horizontal distance to report new data"
        case .minTimeInterval:
            return "Minimum time interval to report new data"
        }
    }
    
}

class GPSController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let sections: [GPSSection] = GPSSection.allCases
    
    @IBOutlet public var tableView: UITableView!
    @IBOutlet public var resultLog: UITextView!
    
    var currentRequestOptions = GPSLocationOptions()

    @IBAction public func clearText(_ sender: Any) {
        resultLog.text = ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        self.navigationItem.title = "GPS Location"
        
        NotificationCenter.default.addObserver(self, selector: #selector(newNotificationReceived), name: Notification.Name(AppDelegate.NOTIFICATION_GPS_DATA), object: nil)
    }
    
    @objc func newNotificationReceived(_ notification: Notification) {
        guard let data = notification.object as? Result<GPSLocationRequest.ProducedData, LocatorErrors> else {
            return
        }
        
        switch data {
        case .failure(let error):
            resultLog.addOnTop("- \(error.localizedDescription)")

        case .success(let data):
            resultLog.addOnTop("- \(data.description)")

        }
    }
    
    private func reloadData() {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == sections.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: GPSActionCell.cellIdentifier, for: indexPath) as! GPSActionCell
            cell.onTap = { [weak self] in
                self?.enqueueGPSRequest()
            }
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: GPSControllerCell.cellIdentifier, for: indexPath) as! GPSControllerCell
        let item = sections[indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        
        switch item {
        case .accuracy:
            cell.valueLabel.text = currentRequestOptions.accuracy.description
        case .activityType:
            cell.valueLabel.text = currentRequestOptions.activityType.description
        case .minDistance:
            cell.valueLabel.text = currentRequestOptions.minDistance?.formattedValue ?? "any"
        case .minTimeInterval:
            cell.valueLabel.text = currentRequestOptions.minTimeInterval?.format() ?? "any"
        case .subscription:
            cell.valueLabel.text = currentRequestOptions.subscription.description
        case .timeoutInterval:
            cell.valueLabel.text = currentRequestOptions.minTimeInterval?.format() ?? "any"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "NEW GPS REQUEST"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.row]

        switch item {
        case .accuracy:
            showAccuracyMenu()
        case .activityType:
            showActivityMenu()
        case .minDistance:
            showMinDistanceMenu()
        case .minTimeInterval:
            showMinIntervalMenu()
        case .subscription:
            showSubscriptionMenu()
        case .timeoutInterval:
            showTimeoutIntervalMenu()
        }
        
    }
    
    private func showAccuracyMenu() {
        let accuracyLevels: [UIAlertController.ActionSheetOption] = [
            GPSLocationOptions.Accuracy.any,
            GPSLocationOptions.Accuracy.city,
            GPSLocationOptions.Accuracy.neighborhood,
            GPSLocationOptions.Accuracy.block,
            GPSLocationOptions.Accuracy.house,
            GPSLocationOptions.Accuracy.room
        ].map { [weak self] item in
            (item.description, { _ in
                self?.currentRequestOptions.accuracy = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Accuracy", message: nil, options: accuracyLevels)
    }
    
    private func showActivityMenu() {
        let accuracyLevels: [UIAlertController.ActionSheetOption] = [
            CLActivityType.airborne,
            CLActivityType.automotiveNavigation,
            CLActivityType.fitness,
            CLActivityType.other,
            CLActivityType.otherNavigation,
        ].map { [weak self] item in
            (item.description, { _ in
                self?.currentRequestOptions.activityType = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Activity Type", message: nil, options: accuracyLevels)
    }
    
    private func showMinDistanceMenu() {
        UIAlertController.showInputFieldSheet(title: "Select Minimum Distance",
                                              message: "Minimum horizontal distance to report new fresh data (meters)") { value in
            if let value = value {
                self.currentRequestOptions.minDistance = CLLocationDistance(value)
            } else {
                self.currentRequestOptions.minDistance = nil
            }
        }
    }
    
    private func showMinIntervalMenu() {
        UIAlertController.showInputFieldSheet(title: "Select Minimum Interval",
                                              message: "Minimum interval to report new fresh data (seconds)") { value in
            if let value = value {
                self.currentRequestOptions.minTimeInterval = TimeInterval(value)
            } else {
                self.currentRequestOptions.minTimeInterval = nil
            }
        }
    }
    
    private func showSubscriptionMenu() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = [
            GPSLocationOptions.Subscription.single,
            GPSLocationOptions.Subscription.continous,
            GPSLocationOptions.Subscription.significant
        ].map { [weak self] item in
            (item.description, { _ in
                self?.currentRequestOptions.subscription = item
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Subscription", message: nil, options: subscriptionTypes)
    }
    
    private func showTimeoutIntervalMenu() {
        let subscriptionTypes: [UIAlertController.ActionSheetOption] = ([
            nil, -5, -10, 5, 10
        ] as [Int?]
        ).map { [weak self] item in
            let title = (item == nil ? "No Timeout" : (item! < 0 ? "Delayed \(abs(item!))s" : "Immediate \(item!)s"))
            return (title, { _ in
                if let value = item {
                    if value < 0 {
                        self?.currentRequestOptions.timeout = GPSLocationOptions.Timeout.delayed(TimeInterval(value))
                    } else {
                        self?.currentRequestOptions.timeout = GPSLocationOptions.Timeout.immediate(TimeInterval(value))
                    }
                } else {
                    self?.currentRequestOptions.timeout = nil
                }
                self?.reloadData()
            })
        }
        
        UIAlertController.showActionSheet(title: "Select Subscription",
                                          message: "Delayed starts only after the necessary authorization will be granted",
                                          options: subscriptionTypes)
    }

    private func enqueueGPSRequest() {
        let request = Locator.shared.gpsLocationWith(currentRequestOptions)
        UIAlertController.showAlert(title: "Added request \(request.uuid)")
        
        currentRequestOptions = GPSLocationOptions()
        reloadData()
        
        AppDelegate.attachSubscribersToGPS([request])
    }
    
}


public class GPSControllerCell: UITableViewCell {
    public static let cellIdentifier = "GPSControllerCell"
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var subtitleLabel: UILabel!
    @IBOutlet public var valueLabel: UILabel!
    
}

public class GPSActionCell: UITableViewCell {
    public static let cellIdentifier = "GPSActionCell"

    @IBOutlet public var actionButton: UIButton!
    
    public var onTap: (() -> Void)?

    @IBAction public func callAction(_ sender: Any?) {
        onTap?()
    }
    
}

extension TimeInterval {

    func format() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1

        return formatter.string(from: self)!
    }
    
}

extension UITextView {
    
    public func addOnTop(_ text: String) {
        if let position = textRange(from: beginningOfDocument, to: beginningOfDocument) {
            replace(position, withText: text)
        }
    }
    
}
