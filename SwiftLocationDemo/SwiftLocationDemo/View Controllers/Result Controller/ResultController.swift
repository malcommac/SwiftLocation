//
//  ResultController.swift
//  SwiftLocationDemo
//
//  Created by daniele on 06/11/2020.
//

import UIKit
import SwiftLocation

public class ResultController: UIViewController {
    
    @IBOutlet public var resultTextView: UITextView!
    
    public static func showWithResult<T: CustomStringConvertible>(_ data: Result<T, LocatorErrors>, in sourceController: UIViewController) {
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
    
}
