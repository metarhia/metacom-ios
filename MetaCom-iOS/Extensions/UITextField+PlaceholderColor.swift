//
//  UITextField+PlaceholderColor.swift
//  Swift+Extensions
//
//  Created by iKing on 17.05.17.
//  Copyright © 2017 iKing. All rights reserved.
//

import UIKit

extension UITextField {
	
	@IBInspectable var placeholderColor: UIColor {
		get {
			var range = NSMakeRange(0, (placeholder ?? "").characters.count)
			guard let color = attributedPlaceholder?.attribute(NSForegroundColorAttributeName, at: 0, effectiveRange: &range) as? UIColor else {
				return UIColor.clear
			}
			return color
		}
		set {
			let attributedText: NSMutableAttributedString
			
			if let attributedPlaceholder = attributedPlaceholder {
				attributedText = NSMutableAttributedString(attributedString: attributedPlaceholder)
			} else if let placeholder = placeholder {
				attributedText = NSMutableAttributedString(string: placeholder)
			} else {
				attributedText = NSMutableAttributedString(string: "")
			}
			
			let range = NSMakeRange(0, attributedText.length)
			attributedText.addAttribute(NSForegroundColorAttributeName, value: newValue, range: range)
			attributedPlaceholder = attributedText
		}
	}
}
