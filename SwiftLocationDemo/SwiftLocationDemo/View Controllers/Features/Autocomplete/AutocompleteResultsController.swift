//
//  AutocompleteResultsController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 08/11/2020.
//

import UIKit
import SwiftLocation

public class AutocompleteResultsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - IBOutlets
    
    @IBOutlet public var resultsTableView: UITableView!

    // MARK: - Private Properties
    
    private var list: AutocompleteRequest.ProducedData?
    private var service: AutocompleteProtocol?

    // MARK: - Initialization
    
    public static func create(list: AutocompleteRequest.ProducedData, forService service: AutocompleteProtocol?) -> AutocompleteResultsController {
        let s = UIStoryboard(name: "AutocompleteController", bundle: nil)
        let vc = s.instantiateViewController(identifier: "AutocompleteResultsController") as! AutocompleteResultsController
        vc.list = list
        vc.service = service
        return vc
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableView.tableFooterView = UIView()
        self.navigationItem.title = "\(list?.count ?? 0) Suggestions"

    }
    
    // MARK: - TableView DataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        list?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = list![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.ID) as! StandardCellSetting
        cell.titleLabel.text = result.partialAddress?.title
        cell.subtitleLabel.text = result.partialAddress?.subtitle
        cell.valueLabel.text = result.place?.coordinates.description
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let result = list?[indexPath.row],
              let detailService = createRequestToGetDetailForResult(result) else {
            return
        }
                
        let loader = UIAlertController.showLoader(message: "Getting details for place \(result.description)...")
        Locator.shared.autocompleteWith(detailService).then(queue: .main) { result in
            loader.dismiss(animated: true, completion: nil)
            ResultController.showWithResult(result, in: self)
        }
    }
    
    // MARK: - Private Functions
    
    private func createRequestToGetDetailForResult(_ result: Autocomplete.Data?) -> AutocompleteProtocol? {
        switch service {
        case is Autocomplete.Apple:
            return Autocomplete.Apple(detailsFor: result)
        case is Autocomplete.Google:
            return Autocomplete.Google(detailsFor: result, APIKey: service?.asGoogle?.APIKey ?? "")
        case is Autocomplete.Here:
            return Autocomplete.Here(detailsFor: result, APIKey: service?.asHere?.APIKey ?? "")
        default:
            return nil
        }
    }
    
}
