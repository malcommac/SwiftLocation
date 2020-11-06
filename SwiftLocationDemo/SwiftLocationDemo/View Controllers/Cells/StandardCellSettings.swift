//
//  StandardCellSettings.swift
//  SwiftLocationDemo
//
//  Created by daniele on 06/11/2020.
//

import UIKit

public class StandardCellSetting: UITableViewCell {
    static let ID = "StandardCellSetting"
    static let Height: CGFloat = 50
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var subtitleLabel: UILabel!
    @IBOutlet public var valueLabel: UILabel!

    public var item: CellRepresentableItem? {
        didSet {
            titleLabel.text = item?.title ?? ""
            subtitleLabel.text = item?.subtitle ?? ""
        }
    }
    
}
