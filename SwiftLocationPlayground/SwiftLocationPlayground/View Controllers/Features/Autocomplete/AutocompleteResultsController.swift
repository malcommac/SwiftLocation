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
        
        resultsTableView.registerUINibForClass(StandardCellSetting.self)
        resultsTableView.registerUINibForClass(StandardCellButton.self)
        resultsTableView.tableFooterView = UIView()
        self.navigationItem.title = "\(list?.count ?? 0) Suggestions"

    }
    
    // MARK: - TableView DataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        list?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = list![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StandardCellSetting.defaultReuseIdentifier) as! StandardCellSetting
        cell.titleLabel.text = result.partialAddress?.title
        cell.subtitleLabel.text = result.partialAddress?.subtitle
        cell.valueLabel.text = result.place?.coordinates.description
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let result = list?[indexPath.row],
              let detailService = createRequestToGetDetailForResult(result.partialAddress) else {
            return
        }
                
        let loader = UIAlertController.showLoader(message: "Getting details for place \(result.description)...")
        SwiftLocation.autocompleteWith(detailService).then(queue: .main) { result in
            loader.dismiss(animated: true, completion: nil)
            ResultController.showWithResult(result, in: self)
        }
    }
    
    // MARK: - Private Functions
    
    private func createRequestToGetDetailForResult(_ result: PartialAddressMatch?) -> AutocompleteProtocol? {
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
