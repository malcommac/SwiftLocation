//
//  ReverseAddressVC.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 08/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit

class ReverseAddressVC: UIViewController {

    @IBOutlet weak var twAddress: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: - GUI
extension ReverseAddressVC
{
    func guiInit()
    {
        self.twAddress.text = ""
    }
    
    

}