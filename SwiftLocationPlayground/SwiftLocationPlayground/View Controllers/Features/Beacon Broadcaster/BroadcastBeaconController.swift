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
import CoreBluetooth
import CoreLocation

// MARK: - BroadcastBeaconController

public class BroadcastBeaconController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Private Properties
    
    /// Settings list.
    private var rows: [RowSetting] = [.enable, .UUID, .majorUUID, .minorUUID]
    
    /// Beacon to broadcast.
    private var broadcastBeacon: BroadcastedBeacon?
    
    // MARK: - IBOutlets

    @IBOutlet public var tableView: UITableView?
    
    // MARK: - Initialization

    public static func create() -> BroadcastBeaconController {
        let s = UIStoryboard(name: "BeaconController", bundle: nil)
        return s.instantiateViewController(withIdentifier: "BroadcastBeaconController") as! BroadcastBeaconController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.registerUINibForClass(ToggleCell.self)
        tableView?.registerUINibForClass(StandardCellSetting.self)
        self.navigationItem.title = "Broadcast Beacon"
    }
    
    // MARK: - TableView DataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = rows[indexPath.row]
        if item == .enable {
            let cell = tableView.dequeueReusableCell(withIdentifier: ToggleCell.defaultReuseIdentifier, for: indexPath) as! ToggleCell
            cell.titleLabel.text = item.title
            cell.toggleButton.isOn = LocationManager.shared.isBeaconBroadcastActive
            cell.accessoryType = .none
            cell.onToggle = { [weak self] isOn in
                self?.setToggleStateTo(isOn)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier, for: indexPath) as! StandardCellSetting
            cell.titleLabel.text = item.title
            cell.subtitleLabel.text = item.subtitle
            cell.accessoryType = .none
            
            switch item {
            case .UUID:
                cell.valueLabel.text = broadcastBeacon?.uuid ?? NOT_SET
            case .majorUUID:
                cell.valueLabel.text = broadcastBeacon?.region?.major?.description ?? NOT_SET
            case .minorUUID:
                cell.valueLabel.text = broadcastBeacon?.region?.minor?.description ?? NOT_SET
            default:
                break
            }
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    private func requestBeaconData(_ completion: @escaping ((BroadcastedBeacon?) -> Void)) {
        UIAlertController.showInputFieldSheet(title: "UUID") { UUID in
            guard let UUID = UUID, !UUID.isEmpty else {
                completion(nil)
                return
            }
            
            UIAlertController.showInputFieldSheet(title: "Major, Minor") { value in
                guard let majorAndMinor = value?.components(separatedBy: ","), majorAndMinor.count == 2 else {
                    completion(nil)
                    return
                }
                
                guard let major = CLBeaconMajorValue(majorAndMinor[0]),
                      let minor = CLBeaconMinorValue(majorAndMinor[1]) else {
                    completion(nil)
                    return
                }
                
                
                UIAlertController.showInputFieldSheet(title: "Identifier") { identifier in
                    
                    guard let beacon = BroadcastedBeacon(UUID: UUID,
                                                   majorID: major,
                                                   minorID: minor,
                                                   identifier: identifier ?? "") else {
                        completion(nil)
                        return
                    }
                    
                    completion(beacon)
                }
            }
        }
    }
    
    private func setToggleStateTo(_ newValue: Bool) {
        if newValue {
            requestBeaconData { [weak self] newBeacon in
                self?.broadcastBeacon = newBeacon
                
                guard let newBeacon = newBeacon else {
                    UIAlertController.showAlert(title: "Invalid beacon parameters",
                                                message: "Check data and try again")
                    self?.tableView?.reloadData()
                    return
                }
                
                SwiftLocation.broadcastAsBeacon(newBeacon) { error in
                    self?.tableView?.reloadData()
                    if let error = error {
                        UIAlertController.showAlert(title: "Failed to broadcast",
                                                    message: error.localizedDescription)
                    } else {
                        UIAlertController.showAlert(title: "Broadcasting beacon",
                                                    message: "It works until the app is in foreground or you stop manually it")
                    }
                }
            }
            
        } else {
            UIAlertController.showBoolSheet(title: "Stop broadcasting?", message: nil) { [weak self] value in
                SwiftLocation.stopBroadcasting()
                self?.broadcastBeacon = nil
                self?.tableView?.reloadData()
            }
        }
    }
    
}

// MARK: - BroadcastBeaconController RowSetting

fileprivate extension BroadcastBeaconController {
    
    enum RowSetting: CellRepresentableItem {
        case enable
        case UUID
        case majorUUID
        case minorUUID
        
        var title: String {
            switch self {
            case .enable:       return "Status"
            case .UUID:         return "UUID"
            case .majorUUID:    return "Major"
            case .minorUUID:    return "Minor"
            }
        }
        
        var subtitle: String {
            ""
        }
        
        var icon: UIImage? {
            nil
        }
        
    }
    
}
