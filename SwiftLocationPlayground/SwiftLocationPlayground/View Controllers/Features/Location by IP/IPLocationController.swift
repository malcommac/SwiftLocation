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

public class IPLocationController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - IBOutlets
    
    @IBOutlet public var tableView: UITableView!
    @IBOutlet public var resultLog: UITextView!

    // MARK: - Private Properties

    private var rows: [RowSetting] = [.service, .createRequest]
    private var service: IPServiceProtocol?
    private var runningRequest: IPLocationRequest?
    
    // MARK: - Initialization

    public static func create() -> IPLocationController {
        let s = UIStoryboard(name: "IPLocationController", bundle: nil)
        return s.instantiateInitialViewController() as! IPLocationController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        resultLog.text = ""
        tableView.registerUINibForClass(StandardCellSetting.self)
        tableView.registerUINibForClass(StandardCellButton.self)
        tableView.tableFooterView = UIView()
        self.navigationItem.title = "Coordinates By IP"
    }
    
    // MARK: - TableView DataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kind = rows[indexPath.row]
        
        if kind == .createRequest {
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellButton.defaultReuseIdentifier) as! StandardCellButton
            cell.onAction = {
                self.createRequest()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier) as! StandardCellSetting
            self.valueForCell(cell, kind: kind)
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .createRequest:
            return StandardCellButton.Height
        default:
            return StandardCellSetting.Height
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch rows[indexPath.row] {
        case .service:
            
            var actions = [UIAlertController.ActionSheetOption]()
            IPServiceDecoders.allCases.forEach { item in
                actions.append((item.rawValue, { action in
                    switch item {
                    case .ipstack:
                        self.service = IPLocation.IPStack(APIKey: "")
                    case .ipdata:
                        self.service = IPLocation.IPData(APIKey: "")
                    case .ipinfo:
                        self.service = IPLocation.IPInfo(APIKey: "")
                    case .ipapi:
                        self.service = IPLocation.IPApi()
                    case .ipgeolocation:
                        self.service = IPLocation.IPGeolocation(APIKey: "")
                    case .ipify:
                        self.service = IPLocation.IPify(APIKey: "")
                    }
                    self.reloadData()
                }))
            }
            
            UIAlertController.showActionSheet(title: "Select Service", message: "Select service to use in order to get IP. Some services may require registration and API Key value.",
                                              options: actions)
            
        default:
            didSelectRow(rows[indexPath.row])
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return rows[indexPath.row] != .createRequest
    }
    
    // MARK: - Private Functions
    
    private func didSelectRow(_ kind: RowSetting) {
        guard let service = service else { return }
        
        switch kind {
        case .targetIP:
            UIAlertController.showInputFieldSheet(title: "Target IP", message: "Specify an IP you want to query if it's different from your machine IP. Empty to use machine's IP.") { value in
                service.targetIP = (value?.isEmpty ?? true ? nil : value!)
                self.reloadData()
            }
            
        case .locale:
            UIAlertController.showInputFieldSheet(title: "Locale", message: "Read the documentation of the service to know the value you can use") { value in
                service.locale = (value?.isEmpty ?? true ? nil : value!)
                self.reloadData()
            }
            
        case .timeout:
            let values: [UIAlertController.ActionSheetOption] = [
                ("1s", { _ in service.timeout = 1; self.reloadData() }),
                ("5s", { _ in service.timeout = 5; self.reloadData() }),
                ("10s", { _ in service.timeout = 10; self.reloadData() }),
            ]
            UIAlertController.showActionSheet(title: "Timeout Interval", message: "Maximum number of seconds waiting for response.",
                                              options: values)
            
        case .hostnameLookup:
            UIAlertController.showBoolSheet(title: "Would you enable hostname lookup?", message: "Retrive information about the hostname the given IP address resolves to") { value in
                
                switch service {
                case let ipApi as IPLocation.IPApi:
                    ipApi.hostnameLookup = value
                case let ipStack as IPLocation.IPStack:
                    ipStack.hostnameLookup = value
                    
                default:
                    break
                }
                
                self.reloadData()
            }
            
        case .apiKey:
            UIAlertController.showInputFieldSheet(title: "API Key", message: "See docs about how to get the API key") { newKey in
                service.APIKey = newKey ?? ""
                self.reloadData()
            }
            
        default:
            break
        }
        
    }
    
    // MARK: - Settings Formatter
    
    private func setupRowsForService() {
        var serviceRows = [RowSetting]([.service])
        
        if let service = service {
            switch service {
            case _ as IPLocation.IPApi:
                serviceRows.append(contentsOf: [
                    .targetIP,
                    .locale,
                    .hostnameLookup,
                    .timeout
                ])
             
            case _ as IPLocation.IPStack:
                serviceRows.append(contentsOf: [
                    .apiKey,
                    .targetIP,
                    .locale,
                    .hostnameLookup,
                    .timeout
                ])
                
            default: // IPInfo, IPGeolocation, IPData, IPify
                serviceRows.append(contentsOf: [
                    .apiKey,
                    .targetIP,
                    .locale,
                    .timeout
                ])
                
            }
        }
        
        serviceRows.append(.createRequest)
        self.rows = serviceRows
    }
    
    private func valueForCell(_ cell: StandardCellSetting, kind: RowSetting) {
        cell.titleLabel.text = kind.title
        cell.subtitleLabel.text = kind.subtitle
        
        if let service = service {
            switch service {
            case let ipApi as IPLocation.IPApi:
                cell.valueLabel.text = ipApi_valueForKind(ipApi, kind: kind)
                
            case let ipStack as IPLocation.IPStack:
                cell.valueLabel.text = ipStack_valueForKind(ipStack, kind: kind)
                
            default:
                cell.valueLabel.text = sharedService_valueForKind(service, kind: kind)
            }
        } else {
            cell.valueLabel.text = NOT_SET
        }
    }

    private func ipApi_valueForKind(_ service: IPLocation.IPApi, kind: RowSetting) -> String {
        switch kind {
        case .hostnameLookup:   return service.hostnameLookup.description
        default:                return sharedService_valueForKind(service, kind: kind)
        }
    }
    
    private func ipStack_valueForKind(_ service: IPLocation.IPStack, kind: RowSetting) -> String {
        switch kind {
        case .hostnameLookup:   return service.hostnameLookup.description
        default:                return sharedService_valueForKind(service, kind: kind)
        }
    }
    
    private func sharedService_valueForKind(_ service: IPServiceProtocol, kind: RowSetting) -> String {
        switch kind {
        case .targetIP:     return service.targetIP ?? "Current"
        case .locale:       return service.locale ?? "Current"
        case .timeout:      return "\(service.timeout)s"
        case .service:      return service.jsonServiceDecoder.rawValue
        case .apiKey:       return (service.APIKey?.isEmpty ?? true) ? NOT_SET : service.APIKey!
        default:            return ""
        }
    }
    
    // MARK: - Actions
    
    private func reloadData() {
        setupRowsForService()
        
        tableView.reloadData()
    }
    
    private func createRequest() {
        guard let service = service else {
            UIAlertController.showAlert(title: "You must select a service first")
            return
        }
        
        let loader = UIAlertController.showLoader(message: "Getting information from IP address...")
        
        runningRequest = SwiftLocation.ipLocationWith(service)
        runningRequest?.then(queue: .main, { [weak self] result in
            guard let self = self else { return }
            
            loader.dismiss(animated: true, completion: nil)
            ResultController.showWithResult(result, in: self)
            //self.resetService()
        })
    }
    
    private func resetService() {
        runningRequest = nil
        service = nil
        reloadData()
    }
    
}

// MARK: - IPLocationController RowSetting

fileprivate extension IPLocationController {
    
    enum RowSetting {
        case service
        case targetIP
        case locale
        case hostnameLookup
        case timeout
        case apiKey
        case createRequest
        
        var title: String {
            switch self {
            case .service:          return "Service"
            case .targetIP:         return "Target IP"
            case .locale:           return "Language"
            case .hostnameLookup:   return "Hostname Lookup"
            case .timeout:          return "Timeout (s)"
            case .apiKey:           return "API Key"
            default:                return ""
            }
        }
        
        var subtitle: String {
            switch self {
            case .service:          return "Service to use for request"
            case .targetIP:         return "If not set it uses current machine IP"
            case .locale:           return "If not set the device's language is used"
            case .hostnameLookup:   return "Hostname info of the given IP"
            case .timeout:          return "Timeout of call"
            case .apiKey:           return "Required for this service. See doc."
            default:                return ""
            }
        }
        
    }
    
}
