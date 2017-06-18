//
//  DotsActivityIndicatorView.swift
//  MetaCom-iOS
//
//  Created by iKing on 17.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

@IBDesignable class DotsActivityIndicatorView: UIView {
	
	@IBInspectable var isAnimating: Bool = false {
		didSet {
			guard isAnimating != oldValue else {
				return
			}
			
			#if TARGET_INTERFACE_BUILDER
				return
			#endif
			
			if isAnimating {
				startAnimation()
			} else {
				stopAnimation()
			}
		}
	}
	
	private weak var dotsStackView: UIStackView!
	
	private var dots: [DotView] {
		return dotsStackView.arrangedSubviews as? [DotView] ?? []
	}
	
	private var highlightedDotIndex: Int = 0
	
	private weak var animationTimer: Timer?
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		clipsToBounds = true
		let stackView = UIStackView(frame: bounds)
		stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		stackView.distribution = .fillEqually
		stackView.spacing = 8
		
		for _ in 0 ..< 3 {
			stackView.addArrangedSubview(DotView())
		}

		addSubview(stackView)
		
		dotsStackView = stackView
		
		dots.first?.isHighlighted = true
	}
	
	override var intrinsicContentSize: CGSize {
		return CGSize(width: 52, height: 12)
	}
	
	private func startAnimation() {
		let timer = Timer(timeInterval: 0.2, repeats: true) { _ in
			self.highlightNextDot()
		}
		RunLoop.main.add(timer, forMode: .commonModes)
		animationTimer = timer
	}
	
	private func stopAnimation() {
		animationTimer?.invalidate()
	}
	
	@objc private func highlightNextDot() {
		let dots = self.dots
		dots[highlightedDotIndex].setHighlighted(false)
		highlightedDotIndex = (highlightedDotIndex + 1) % dots.count
		dots[highlightedDotIndex].setHighlighted(true)
	}
	
}
