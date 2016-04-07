//
//  SamplesViewController.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 07/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit


class SamplesViewController: UIViewController, UITableViewDelegate , UITableViewDataSource {

    @IBOutlet weak var tableViewMenu: UITableView!
    
    let menuArr:[String] = ["Find My Location" , "Reverse Geocode"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Swift Location"
        
        let nib:UINib = UINib(nibName: "MenuCell", bundle: nil)
        self.tableViewMenu.registerNib(nib, forCellReuseIdentifier: "menuCell")
        
        self.tableViewMenu.delegate = self
        self.tableViewMenu.dataSource = self
        
        
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


// MARK: - TableView Delegate / Datasource
extension SamplesViewController
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuArr.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:MenuCell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuCell
        
        let header = menuArr[indexPath.row]
        
        cell.lblMenuCell.text = header
        
        return cell
    }
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if(indexPath.row == 0)
        {
            // find my location
            let vc:FindMyLocationVC = FindMyLocationVC(nibName:"FindMyLocationVC", bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if(indexPath.row == 1)
        {
            // reverse geocode
        }
        else if(indexPath.row == 2)
        {
            
        }
        
        
    }
    
    
    
    
    
}