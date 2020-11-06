//
//  ActionCell.swift
//  SwiftLocationDemo
//
//  Created by daniele on 06/11/2020.
//

import UIKit

public protocol CellRepresentableItem {
    
    var title: String { get }
    var icon: UIImage? { get }
    var subtitle: String { get }
    
}

public class ActionCell: UITableViewCell {
    public static let RIdentifier = "ActionCell"
    
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var subtitleLabel: UILabel!
    @IBOutlet public var iconImageView: UIImageView!
    
    public var item: CellRepresentableItem? {
        didSet {
            guard let newItem = item else {
                titleLabel.text = ""
                subtitleLabel.text = ""
                iconImageView.image = nil
                return
            }
            
            titleLabel.text = newItem.title
            subtitleLabel.text = newItem.subtitle
            iconImageView.image = newItem.icon
        }
    }
    
}
