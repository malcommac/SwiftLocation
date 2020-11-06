//
//  Autocomplete.swift
//  SwiftLocationDemo
//
//  Created by daniele on 31/10/2020.
//

import UIKit
import SwiftLocation
import MapKit
import CoreLocation

public class AutocompleteController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var rows = [RowSetting]([.service])
    
    @IBOutlet public var settingsTableView: UITableView!
    @IBOutlet public var resultsTableView: UITableView!

    private var autocompleteService: AutocompleteProtocol?
    private var autocompleteResults: AutocompleteRequest.ProducedData?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Autocomplete Address"
        
        settingsTableView.tableFooterView = UIView()
        resultsTableView.tableFooterView = UIView()
    }
    
    public static func create() -> AutocompleteController {
        let s = UIStoryboard(name: "AutocompleteController", bundle: nil)
        return s.instantiateInitialViewController() as! AutocompleteController
    }
    
    @IBAction public func clearResults(_ sender: Any?) {
        autocompleteResults?.removeAll()
        resultsTableView.reloadData()
    }
    
    // MARK: - TableView Data Source Delegates
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == settingsTableView {
            return settingsTableView(tableView, numberOfRowsInSection: section)
        } else {
            return resultsTableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == settingsTableView {
            return settingsTableView(tableView, cellForRowAt: indexPath)
        } else {
            return resultsTableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == settingsTableView {
            return settingsTableView(tableView, didSelectRowAt: indexPath)
        } else {
            return resultsTableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    // MARK: - Results TableView Data Source

    private func resultsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        autocompleteResults?.count ?? 0
    }
    
    private func resultsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = autocompleteResults![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.ID) as! StandardCellSetting
        cell.titleLabel.text = result.partialAddress?.title
        cell.subtitleLabel.text = result.partialAddress?.subtitle
        cell.valueLabel.text = result.place?.coordinates.description
        
        return cell
    }
    
    private func resultsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let result = autocompleteResults?[indexPath.row],
              let detailService = createRequestToGetDetailForResult(result) else {
            return
        }
                
        let loader = UIAlertController.showLoader(message: "Getting details for place \(result.description)...")
        Locator.shared.autocompleteWith(detailService).then(queue: .main) { result in
            loader.dismiss(animated: true, completion: nil)
            ResultController.showWithResult(result, in: self)
        }
    }
    
    private func createRequestToGetDetailForResult(_ result: Autocomplete.Data?) -> AutocompleteProtocol? {
        switch autocompleteService {
        case is Autocomplete.Apple:
            return Autocomplete.Apple(detailsFor: result)
        default:
            return nil
        }
    }
    
    // MARK: - Settings TableView Data Source
    
    private func settingsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableView == settingsTableView && rows[indexPath.row] == .createRequest {
            return false
        }
        
        return true
    }

    private func settingsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        
        switch row {
        case .createRequest:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellButton.ID) as! StandardCellButton
            cell.buttonAction.setTitle(row.title, for: .normal)
            cell.onAction = { [weak self] in
                self?.createRequest()
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.ID) as! StandardCellSetting
            cell.item = rows[indexPath.row]
            cell.valueLabel.text = valueForKind(rows[indexPath.row])
            return cell
        }
    }
    
    private func settingsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch rows[indexPath.row] {
        case .service:
            selectService()
        case .addressValue:
            selectAutocompleteAddress()
        case .proximityRegion:
            selectProximityRegion()
        case .filterType:
            selectFilterType()
        default:
            break
        }
    }
    
    private func createRequest() {
        guard let service = self.autocompleteService else {
            return
        }

        let loader = UIAlertController.showLoader(message: "Getting information from IP address...")
        let request = Locator.shared.autocompleteWith(service)
        request.then(queue: .main) { result in
            loader.dismiss(animated: false, completion: nil)

            switch result {
            case .failure(let error):
                UIAlertController.showAlert(title: "Error Occurred", message: error.localizedDescription)
                break
            case .success(let data):
                self.autocompleteResults = data
                self.resultsTableView.reloadData()
                break
            }
        }
    }
    
    private func reloadData() {
        defer {
            settingsTableView.reloadData()
        }
        
        guard let service = autocompleteService else {
            self.rows = [.service]
            return
        }
        
        switch service {
        case is Autocomplete.Apple:
            self.rows = [.service, .addressValue, .proximityRegion, .filterType, .createRequest]
        default:
            break
        }
    }
    
    private func valueForKind(_ kind: RowSetting) -> String {
        switch kind {
        case .service:
            return serviceName()
        case .addressValue:
            return autocompleteService?.operation.value ?? "Not Set"
        case .proximityRegion:
            return (autocompleteService as? Autocomplete.Apple)?.proximityRegion?.description ?? "Not Set"
        case .filterType:
            return (autocompleteService as? Autocomplete.Apple)?.resultType.description ?? "Not Set"
        case .locale:
            return ""
        case .limit:
            return "Limit"
        case .APIKey:
            return "API Key"
        default:
            return ""
        }
    }
    
    private func selectProximityRegion() {
        UIAlertController.showInputFieldSheet(title: "Insert proximity region using the forma below",
                                              message: "{LAT},{LNG},{LAT. METERS},{LONG. METERS}") { [weak self] value in
            (self?.autocompleteService as? Autocomplete.Apple)?.proximityRegion = MKCoordinateRegion.fromRawString(value)
            self?.reloadData()
        }
    }
    
    private func selectAutocompleteAddress() {
        UIAlertController.showInputFieldSheet(title: "Insert address to autocomplete", message: nil) { [weak self] value in
            guard let value = value, !value.isEmpty else { return }
            self?.autocompleteService?.operation = AutocompleteOp.partialMatch(value)
            self?.reloadData()
        }
    }
    
    private func selectFilterType() {
        let filterTypes: [UIAlertController.ActionSheetOption] = [
            ("All", { [weak self] _ in
                (self?.autocompleteService as? Autocomplete.Apple)?.resultType = .all
                self?.reloadData()
            }),
            ("Address", { [weak self] _ in
                (self?.autocompleteService as? Autocomplete.Apple)?.resultType = .address
                self?.reloadData()
            }),
            ("Point of Interest", { [weak self] _ in
                (self?.autocompleteService as? Autocomplete.Apple)?.resultType = .pointOfInterest
                self?.reloadData()
            }),
            ("Query", { [weak self] _ in
                (self?.autocompleteService as? Autocomplete.Apple)?.resultType = .query
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select type of result", message: "(A more fine tuned configuration is available via code)", options: filterTypes)
    }
    
    private func selectService() {
        let servicesList: [UIAlertController.ActionSheetOption] = [
            ("Apple", { [weak self] _ in
                self?.autocompleteService = Autocomplete.Apple(partialMatches: "")
                self?.reloadData()
            }),
            ("Google", { [weak self] _ in
                self?.autocompleteService = Autocomplete.Google(partialMatches: "", APIKey: "")
                self?.reloadData()
            }),
            ("Here", { [weak self] _ in
                self?.autocompleteService = Autocomplete.Here(partialMatches: "", APIKey: "")
                self?.reloadData()
            })
        ]
        UIAlertController.showActionSheet(title: "Select a service", message: "Autocomplete services available", options: servicesList)
    }
    
    private func serviceName() -> String {
        guard let service = autocompleteService else {
            self.rows = [.service]
            return "No Set"
        }
        
        switch service {
        case _ as Autocomplete.Apple: return "Apple"
        case _ as Autocomplete.Here: return "Nokia Here"
        case _ as Autocomplete.Google: return "Google"
        default: return ""
        }
    }
    
}

public extension AutocompleteController {
    
    enum RowSetting: CellRepresentableItem {
        case service
        case addressValue
        case proximityRegion
        case filterType
        case locale
        case limit
        case APIKey
        case createRequest
        
        public var title: String {
            switch self {
            case .service: return "Service"
            case .addressValue: return "Address"
            case .proximityRegion: return "Proximity"
            case .filterType: return "Results Type"
            case .locale: return "Locale"
            case .limit: return "Limit"
            case .APIKey: return "API Key"
            default: return "Execute Request"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .service: return "[REQUIRED] Service to use to perform autocomplete"
            case .addressValue: return "[REQUIRED] Address to autocomplete"
            case .proximityRegion: return "To get better contextualized results"
            case .filterType: return "Allowed results"
            case .locale: return "Language of the results"
            case .limit: return "Limit the number of data"
            case .APIKey: return "Required"
            default: return ""
            }
        }
        
        public var icon: UIImage? {
            return nil
        }
        
    }
    
}

extension MKCoordinateRegion: CustomStringConvertible {
    
    static func fromRawString(_ rawString: String?) -> MKCoordinateRegion? {
        guard let values = rawString?.components(separatedBy: ",").compactMap({ CLLocationDegrees($0) }), values.count == 4 else {
            return nil
        }
        
        let coords = CLLocationCoordinate2D(latitude: values[0], longitude: values[1])
        let region = MKCoordinateRegion(center: coords,
                                        latitudinalMeters: CLLocationDistance(values[2]),
                                        longitudinalMeters: CLLocationDistance(values[3]))
        return region
    }
    
    public var description: String {
        "\(center.formattedValue)"
    }
    
}
