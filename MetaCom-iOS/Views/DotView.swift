//
//  DotView.swift
//  MetaCom-iOS
//
//  Created by iKing on 17.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

// MARK: - DotViewDelegate

protocol DotViewDelegate: class {
	
	func dotViewColor(_ dotView: DotView) -> UIColor?
	func dotViewHighlitedColor(_ dotView: DotView) -> UIColor?
	func dotViewAnimationDuration(_ dotView: DotView) -> TimeInterval
}

// MARK: - DotView

@IBDesignable class DotView: UIView {
	
	weak var delegate: DotViewDelegate? {
		didSet {
			update()
		}
	}
	
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
		let duration = animated ? (delegate?.dotViewAnimationDuration(self) ?? 0.3) : 0
		UIView.animate(withDuration: duration) {
			self.isHighlighted = highlighted
		}
	}
	
	///
	/// Updates `DotView` appearance according to its `isHighlighted` property
	///
	func update() {
		backgroundColor = isHighlighted ?
			(delegate?.dotViewHighlitedColor(self) ?? highlightedColor) :
			(delegate?.dotViewColor(self) ?? color)
	}
	
	// MARK: - Initialization
	
	convenience init(delegate: DotViewDelegate) {
		self.init()
		self.delegate = delegate
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
	
	// MARK: - Sizing
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = min(bounds.width, bounds.height) / 2
	}
	
}
