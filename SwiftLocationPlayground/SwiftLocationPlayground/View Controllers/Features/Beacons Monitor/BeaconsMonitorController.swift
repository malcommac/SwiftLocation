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

public class BeaconsMonitorController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var monitoredBeaconsTableView: UITableView!
    @IBOutlet private var logsTableView: UITableView!

    private var beaconRequests = [BeaconRequest]()
    
    // MARK: - Initialization

    public static func create() -> BeaconsMonitorController {
        let s = UIStoryboard(name: "BeaconsMonitorController", bundle: nil)
        return s.instantiateViewController(withIdentifier: "BeaconsMonitorController") as! BeaconsMonitorController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        print(UUID().uuidString)
        
        monitoredBeaconsTableView?.registerUINibForClass(StandardCellSetting.self)
        logsTableView?.registerUINibForClass(StandardCellSetting.self)

        navigationItem.title = "Beacons Monitor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Monitor", style: .plain, target: self, action: #selector(didTapAddBeacon))
    
        NotificationCenter.default.addObserver(self, selector: #selector(reloadLogTableView), name: NOTIFICATION_BEACONS_DATA, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NOTIFICATION_BEACONS_DATA, object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction public func clear() {
        beaconsLogItems.removeAll()
        reloadLogTableView()
    }
    
    @objc private func reloadLogTableView() {
        logsTableView.reloadData()
    }
    
    @objc func didTapAddBeacon(_ sender: Any?) {
        UIAlertController.showActionSheet(title: "Add", message: nil, options: [
            ("Beacon", { [weak self] _ in
                self?.addBeacon({ beacon in
                    guard let beacon = beacon else {
                        UIAlertController.showAlert(title: "Failed to create beacon to monitor")
                        return
                    }
                    
                    let request = SwiftLocation.beacon(beacon)
                    AppDelegate.attachSubscribersToBeacons([request])

                    UIAlertController.showAlert(title: "Monitor Beacon",
                                                message: "Now monitoring beacon with request \(request.uuid)")
                    self?.reloadData()
                })
            }),
            ("Family UUID", { [weak self] _ in
                self?.addFamilyUUID({ UUID in
                    guard let UUID = UUID else {
                        UIAlertController.showAlert(title: "Failed to create beacon family uuid to monitor")
                        return
                    }
                    
                    let request = SwiftLocation.beaconsWithUUID(UUID)
                    AppDelegate.attachSubscribersToBeacons([request])
                    
                    UIAlertController.showAlert(title: "Monitor Family",
                                                message: "Now monitoring family with request \(request.uuid)")
                    self?.reloadData()
                })
            })
        ])
    }
    
    // MARK: - Private Functions
    
    private func addBeacon(_ completion: @escaping ((BeaconRequest.Beacon?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: "UUID") { value in
            guard let value = value, !value.isEmpty, let UUIDInstance = UUID(uuidString: value) else {
                completion(nil)
                return
            }
            
            UIAlertController.showInputFieldSheet(title: "Major, Minor") { value in
                guard let majorAndMinor = value?.components(separatedBy: ",").compactMap({ Int($0) }),
                      majorAndMinor.count == 2 else {
                    completion(nil)
                    return
                }
                
                let beacon = BeaconRequest.Beacon(uuid: UUIDInstance,
                                                  minor: NSNumber(value: majorAndMinor[1]),
                                                  major: NSNumber(value: majorAndMinor[0]))
                completion(beacon)
            }
        }
    }
    
    private func addFamilyUUID(_ completion: @escaping ((UUID?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: "UUID") { value in
            guard let value = value, !value.isEmpty, let UUIDInstance = UUID(uuidString: value) else {
                completion(nil)
                return
            }
            completion(UUIDInstance)
        }
    }
    
    private func reloadData() {
        beaconRequests = Array(SwiftLocation.beaconsRequests.list)
        monitoredBeaconsTableView.reloadData()
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == monitoredBeaconsTableView {
            return beaconRequests.count
        } else if tableView == logsTableView {
            return beaconsLogItems.count
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier, for: indexPath) as! StandardCellSetting
        
        if tableView == monitoredBeaconsTableView {
            let request = beaconRequests[indexPath.row]
            
            if !request.monitoredBeacons.isEmpty {
                cell.titleLabel.text = "\(request.monitoredBeacons.count) Beacons"
                cell.subtitleLabel.text = request.monitoredBeacons.description
            } else {
                cell.titleLabel.text = "\(request.monitoredRegions.count) Regions"
                cell.subtitleLabel.text = request.monitoredRegions.description
            }
            
            cell.valueLabel.text = ""
        } else if tableView == logsTableView {
            let logItem = beaconsLogItems[indexPath.row]
            cell.valueLabel.text = ""

            switch logItem {
            case .failure(let error):
                cell.titleLabel.text = "Error"
                cell.subtitleLabel.text = error.localizedDescription

            case .success(let data):
                cell.titleLabel.text = "New Event"
                cell.subtitleLabel.text = data.description
                
            }
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == monitoredBeaconsTableView else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let request = beaconRequests[indexPath.row]
        UIAlertController.showBoolSheet(title: "Would you stop this request?",
                                        message: request.description) { [weak self] remove in
            if remove {
                request.cancelRequest()
                self?.reloadData()
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        tableView == monitoredBeaconsTableView
    }
    
}
