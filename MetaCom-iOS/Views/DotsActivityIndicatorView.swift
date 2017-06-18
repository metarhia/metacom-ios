//
//  DotsActivityIndicatorView.swift
//  MetaCom-iOS
//
//  Created by iKing on 17.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

@IBDesignable class DotsActivityIndicatorView: UIView {
	
	private weak var dotsStackView: UIStackView!
	
	private var dots: [DotView] {
		return dotsStackView.arrangedSubviews as? [DotView] ?? []
	}
	
	@IBInspectable var isAnimating: Bool = false {
		didSet {
			guard isAnimating != oldValue else {
				return
			}
			
			#if TARGET_INTERFACE_BUILDER
				return
			#endif
			
			if isAnimating {
				startAnimating()
			} else {
				stopAnimating()
			}
		}
	}
	
	// MARK: - Initialization
	
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
		stackView.spacing = Constants.dotsSpacing
		
		for _ in 0 ..< Constants.dotsCount {
			stackView.addArrangedSubview(DotView())
		}

		addSubview(stackView)
		
		dotsStackView = stackView
		
		dots.first?.isHighlighted = true
	}
	
	// MARK: - Sizing
	
	override var intrinsicContentSize: CGSize {
		let dotsCount = CGFloat(Constants.dotsCount)
		let width = Constants.dotDiameter * dotsCount + Constants.dotsSpacing * (dotsCount - 1)
		let height = Constants.dotDiameter
		return CGSize(width: width, height: height)
	}
	
	// MARK: - Animating
	
	private weak var animationTimer: Timer?
	
	private var highlightedDotIndex: Int = 0
	
	private func startAnimating() {
		let timer = Timer(timeInterval: 0.2, repeats: true) { _ in
			self.highlightNextDot()
		}
		animationTimer = timer
		RunLoop.main.add(timer, forMode: .commonModes)
	}
	
	private func stopAnimating() {
		animationTimer?.invalidate()
	}
	
	@objc private func highlightNextDot() {
		let dots = self.dots
		dots[highlightedDotIndex].setHighlighted(false)
		highlightedDotIndex = (highlightedDotIndex + 1) % dots.count
		dots[highlightedDotIndex].setHighlighted(true)
	}
	
	// MARK: - Constants
	
	private struct Constants {
		static let dotsCount: Int = 3
		static let dotDiameter: CGFloat = 12
		static let dotsSpacing: CGFloat = 8
	}
	
}
