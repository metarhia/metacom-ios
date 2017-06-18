//
//  DotView.swift
//  MetaCom-iOS
//
//  Created by iKing on 17.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

@IBDesignable class DotView: UIView {
	
	@IBInspectable var color = UIColor.white.withAlphaComponent(0.55) {
		didSet {
			update()
		}
	}
	
	@IBInspectable var highlightedColor = UIColor.white.withAlphaComponent(0.85) {
		didSet {
			update()
		}
	}
	
	@IBInspectable var isHighlighted: Bool = false {
		didSet {
			guard isHighlighted != oldValue else {
				return
			}
			
			update()
		}
	}
	
	func setHighlighted(_ highlighted: Bool, animated: Bool = true) {
		UIView.animate(withDuration: animated ? 0.4 : 0) {
			self.isHighlighted = highlighted
		}
	}
	
	private func update() {
		backgroundColor = isHighlighted ? highlightedColor : color
	}
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		isHighlighted = aDecoder.decodeBool(forKey: NSStringFromSelector(#selector(getter: isHighlighted)))
		super.init(coder: aDecoder)
		setup()
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(isHighlighted, forKey: NSStringFromSelector(#selector(getter: isHighlighted)))
	}
	
	private func setup() {
		clipsToBounds = true
		update()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = min(bounds.width, bounds.height) / 2
	}
	
}
