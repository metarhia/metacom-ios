//
//  DataMediaView.swift
//  MetaCom-iOS
//
//  Created by iKing on 26.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class DataMediaView: UIView {
	
	private weak var contentView: UIView!
	
	@IBOutlet weak var imageView: UIImageView!
	
	@IBOutlet weak var loadingOverlay: UIView!
	@IBOutlet weak var loadingIndicator: DotedActivityIndicatorView!
	
	var isLoading: Bool = false {
		didSet {
			updateLoadingUI()
		}
	}
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		isLoading = aDecoder.decodeBool(forKey: NSStringFromSelector(#selector(getter: isLoading)))
		super.init(coder: aDecoder)
		setup()
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(isLoading, forKey: NSStringFromSelector(#selector(getter: isLoading)))
	}
	
	private func setup() {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: "DataMediaView", bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
		
		view.frame = bounds
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		addSubview(view)
		
		contentView = view
		
		updateLoadingUI()
	}
	
	private func updateLoadingUI() {
		loadingOverlay.alpha = isLoading ? 1 : 0
		loadingIndicator.isAnimating = isLoading
	}
	
	var insets: UIEdgeInsets = .zero {
		didSet {
			var frame = self.bounds
			frame.size.width -= insets.left + insets.right
			frame.size.height -= insets.top + insets.bottom
			frame.origin.x = insets.left
			frame.origin.y = insets.top
			contentView.frame = frame
		}
	}

}
