//
//  NSLayoutConstraint+ext.swift
//  Tripografy
//
//  Created by aybek can kaya on 22/02/16.
//  Copyright © 2016 aybek can kaya. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    
    public class func applyAutoLayout(superview: UIView, target: UIView, top: Float?, left: Float?, right: Float?, bottom: Float?, height: Float?, width: Float?) {
        
        target.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(target)
        
        var verticalFormat = "V:"
        if let top = top {
            verticalFormat += "|-(\(top))-"
        }
        verticalFormat += "[target"
        if let height = height {
            verticalFormat += "(\(height))"
        }
        verticalFormat += "]"
        if let bottom = bottom {
            verticalFormat += "-(\(bottom))-|"
        }
        let verticalConstrains = NSLayoutConstraint.constraintsWithVisualFormat(verticalFormat, options: [], metrics: nil, views: [ "target" : target ])
        superview.addConstraints(verticalConstrains)
        
        var horizonFormat = "H:"
        if let left = left {
            horizonFormat += "|-(\(left))-"
        }
        horizonFormat += "[target"
        if let width = width {
            horizonFormat += "(\(width))"
        }
        horizonFormat += "]"
        if let right = right {
            horizonFormat += "-(\(right))-|"
        }
        let horizonConstrains = NSLayoutConstraint.constraintsWithVisualFormat(horizonFormat, options: [], metrics: nil, views: [ "target" : target ])
        superview.addConstraints(horizonConstrains)
    }
}

