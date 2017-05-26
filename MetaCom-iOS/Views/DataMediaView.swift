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
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: "DataMediaView", bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
		
		view.frame = bounds
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		addSubview(view)
		
		contentView = view
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
