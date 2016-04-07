//
//  MenuCell.swift
//  SwiftLocationExample
//
//  Created by aybek can kaya on 07/04/16.
//  Copyright © 2016 danielemargutti. All rights reserved.
//

import UIKit

class MenuCell: UITableViewCell {

    @IBOutlet weak var lblMenuCell: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let seperatorView:UIView = UIView()
        seperatorView.backgroundColor = UIColor.blackColor()
        seperatorView.alpha = 0.1
        seperatorView.frame = CGRectMake(0, self.frame.size.height-1 , self.frame.size.width, 1)
        self.addSubview(seperatorView)
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
