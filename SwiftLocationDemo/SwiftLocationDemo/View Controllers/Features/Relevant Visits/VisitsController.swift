//
//  VisitsController.swift
//  SwiftLocationDemo
//
//  Created by daniele margutti on 15/10/2020.
//

import UIKit
import SwiftLocation
import CoreLocation
import MapKit

class VisitsController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet public var toggleButton: UIBarButtonItem?
    @IBOutlet public var tableView: UITableView?
    
    private var history = [CLVisit]()
    private var activeRequest: VisitsRequest?

    private var hasVisitsEnabled: Bool {
        Locator.shared.visitsRequest.hasActiveRequests
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Visits Monitoring"
        
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
    public static func create() -> VisitsController {
        let s = UIStoryboard(name: "VisitsController", bundle: nil)
        return s.instantiateInitialViewController() as! VisitsController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    private func reloadData() {
        toggleButton?.title = (hasVisitsEnabled ? "Disable" : "Enable")
        
        activeRequest = Locator.shared.visitsRequest.list.first
        activeRequest?.cancelAllSubscriptions()
        AppDelegate.attachSubscribersToVisitsRegions([activeRequest])
        
        history = VisitsController.getVisitsFromHistory()
        tableView?.reloadData()
    }
    
    @IBAction public func clearHistory(_ sender: Any?) {
        VisitsController.clearVisitsHistory()
        reloadData()
    }
    
    @IBAction public func toggleVisits(_ sender: Any?) {
        if hasVisitsEnabled {
            activeRequest?.cancelRequest()
            reloadData()
            
        } else {
            let types: [CLActivityType] = [.other, .automotiveNavigation, .fitness, .other, .airborne]
            let actions: [UIAlertController.ActionSheetOption] = types.map { type in
                (type.description, { [weak self] _ in
                    self?.startVisitsMonitoringWithActivityType(type)
                })
            }
            
            UIAlertController.showActionSheet(title: "Select Activity Type",
                                              message: "help the system determine when to pause updates",
                                              options: actions)
        }
    }
    
    private func startVisitsMonitoringWithActivityType(_ type: CLActivityType) {
        activeRequest = Locator.shared.visits(activityType: type)
        reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VisitsControllerCell.identifier) as! VisitsControllerCell
        cell.visit = history[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        110
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "VISITS HISTORY"
    }
    
    // MARK: - History
    
    private static let VisitsHistoryKey = "VisitsHistoryKey"
    
    public static func clearVisitsHistory() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: [CLVisit](),
                                                        requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: VisitsController.VisitsHistoryKey)
        } catch {
            print("Failed to reset history of visits: \(error.localizedDescription)")
        }
    }
    
    public static func addVisitToHistory(_ visit: CLVisit) {
        do {
            var list = getVisitsFromHistory()
            list.append(visit)
            
            let data = try NSKeyedArchiver.archivedData(withRootObject: list, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: VisitsController.VisitsHistoryKey)
        } catch {
            print("Failed to save visits history: \(error.localizedDescription)")
        }
    }
    
    public static func getVisitsFromHistory() -> [CLVisit] {
        do {
            guard let data = UserDefaults.standard.data(forKey: VisitsController.VisitsHistoryKey) else {
                return []
            }
            
            let list = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CLVisit]
            return list ?? []
        } catch {
            print("Failed to decode visits history: \(error.localizedDescription)")
            return []
        }
    }
        
}

public class VisitsControllerCell: UITableViewCell {
    public static let identifier = "VisitsControllerCell"
    
    @IBOutlet public var coordinatesLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var departLabel: UILabel!
    @IBOutlet public var arriveLabel: UILabel!
    
    public weak var visit: CLVisit? {
        didSet {
            coordinatesLabel.text = visit?.coordinate.formattedValue ?? "-"
            if let coordinates = visit?.coordinate {
                 Locator.shared.geocodeWith(Geocoder.Apple(coordinates: coordinates)).then(queue: .main, { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.detailTextLabel?.text = error.localizedDescription
                    case .success(let data):
                        self?.detailTextLabel?.text = data.description
                    }
                })
            } else {
                detailTextLabel?.text = "Not Available"
            }
            departLabel.text = visit?.departureDate.formattedDate ?? "-"
            arriveLabel.text = visit?.arrivalDate.formattedDate ?? "-"
        }
    }

}


public extension Date {
    
    var formattedDate: String {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.string(from: self)
    }
    
}
