//
//  Extensions.swift
//  DemoApp
//
//  Created by dan on 23/04/2019.
//  Copyright © 2019 SwiftLocation. All rights reserved.
//

import UIKit

public class SelectionItem<Value> {
    public var title: String
    public var value: Value?
    
    public init(title: String, value: Value?) {
        self.title = title
        self.value = value
    }
}

extension UIViewController {
    
    public func showPicker<Value>(title: String, msg: String?,
                                  options: [SelectionItem<Value>], onSelect: @escaping ((SelectionItem<Value>) -> Void)) {
        let picker = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        
        for option in options {
            picker.addAction(UIAlertAction(title: option.title, style: .default, handler: { action in
                if let first = options.first(where: { action.title! == $0.title }) {
                    onSelect(first)
                }
            }))
        }
        
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(picker, animated: true, completion: nil)
    }
    
}
