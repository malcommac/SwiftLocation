//
//  StandardCellButton.swift
//  SwiftLocationDemo
//
//  Created by daniele on 06/11/2020.
//

import UIKit

public class StandardCellButton: UITableViewCell {
    static let ID = "StandardCellButton"
    static let Height: CGFloat = 67
    
    public var onAction: (() -> Void)?
    
    @IBOutlet public var buttonAction: UIButton!
    
    @IBAction public func performAction(_ sender: Any?) {
        onAction?()
    }

}
