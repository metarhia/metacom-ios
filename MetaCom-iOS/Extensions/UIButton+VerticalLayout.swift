//
//  UIButton+VerticalLayout.swift
//  MetaCom-iOS
//
//  Created by iKing on 02.08.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIButton {
	
	func centerLayoutVertically(padding: CGFloat = 8.0) {
		let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
		guard let imageSize = self.imageView?.frame.size, let titleSize = self.titleLabel?.sizeThatFits(maxSize) else {
			return
		}
		
		self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: titleSize.height + padding, right: -titleSize.width)
		self.titleEdgeInsets = UIEdgeInsets(top: imageSize.height + padding, left: -imageSize.width, bottom: 0, right: 0)
	}
	
}
