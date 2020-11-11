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

public class ResultController: UIViewController {
    
    @IBOutlet public var resultTextView: UITextView!
    
    public static func showWithResult<T: CustomStringConvertible>(_ data: Result<T, LocationError>, in sourceController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            switch data {
            case .failure(let error):
                UIAlertController.showAlert(title: "An error has occurred", message: error.localizedDescription, controller: sourceController)
            case .success(let res):
                let s = UIStoryboard(name: "ResultController", bundle: nil)
                let vc = s.instantiateInitialViewController() as! ResultController
                _ = vc.view
                vc.resultTextView.text = res.description
                sourceController.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    public static func showWithData(_ rawData: String, in sourceController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let s = UIStoryboard(name: "ResultController", bundle: nil)
            let vc = s.instantiateInitialViewController() as! ResultController
            _ = vc.view
            vc.resultTextView.text = rawData
            sourceController.present(vc, animated: true, completion: nil)
        }
    }
    
}
