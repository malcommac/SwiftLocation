//
//  ToggleCell.swift
//  SwiftLocationPlayground
//
//  Created by daniele on 09/11/2020.
//

import UIKit

public class ToggleCell: UITableViewCell {
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var toggleButton: UISwitch!

    public var onToggle: ((Bool) -> Void)?
    
    @IBAction public func toggleButton(_ sender: Any?) {
        onToggle?(toggleButton.isOn)
    }
    
}
