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
import MapKit

class VisitsController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet public var toggleButton: UIBarButtonItem?
    @IBOutlet public var tableView: UITableView?
    
    private var history = [CLVisit]()
    private var activeRequest: VisitsRequest?

    private var hasVisitsEnabled: Bool {
        SwiftLocation.visitsRequest.hasActiveRequests
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Visits Locations"
        
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NOTIFICATION_VISITS_DATA, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_VISITS_DATA, object: nil)
    }
    
    public static func create() -> VisitsController {
        let s = UIStoryboard(name: "VisitsController", bundle: nil)
        return s.instantiateInitialViewController() as! VisitsController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    @objc func reloadData() {
        toggleButton?.title = (hasVisitsEnabled ? "Stop" : "Start")
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
        activeRequest = SwiftLocation.visits(activityType: type)
        AppDelegate.attachSubscribersToVisitsRegions([activeRequest])
        reloadData()
        
        UIAlertController.showAlert(title: "Request added successfully", message: "Updates will be available through notifications and inside the status panel.")
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGray.withAlphaComponent(0.1)

        // swiftlint:disable force_cast
        let header : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.darkGray
        header.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
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
        return "Visited Location History"
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
                 SwiftLocation.geocodeWith(Geocoder.Apple(coordinates: coordinates)).then(queue: .main, { [weak self] result in
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
