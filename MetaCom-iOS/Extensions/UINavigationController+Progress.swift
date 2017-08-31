//
//  UINavigationController+Progress.swift
//  MetaCom-iOS
//
//  Created by iKing on 15.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

private class ProgressView: UIView {
	
	private var progressView = UIView()
	
	var progress: Double = 0 {
		didSet {
			updateProgressView()
		}
	}
	
	private func updateProgressView() {
		var progressFrame = self.bounds
		progressFrame.size.width = self.bounds.width * CGFloat(progress)
		progressView.frame = progressFrame
		progressView.backgroundColor = tintColor
	}
	
	override var tintColor: UIColor! {
		get {
			return super.tintColor
		}
		set {
			super.tintColor = newValue
			progressView.backgroundColor = newValue
		}
	}
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		progress = aDecoder.decodeDouble(forKey: NSStringFromSelector(#selector(getter: progress)))
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		self.addSubview(progressView)
		tintColor = .defaultTint
		updateProgressView()
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(progress, forKey: NSStringFromSelector(#selector(getter: progress)))
	}
	
	override var frame: CGRect {
		get {
			return super.frame
		}
		set {
			super.frame = newValue
			updateProgressView()
		}
	}
}

extension UINavigationController {
	
	private var progressView: ProgressView {
		if let view = self.navigationBar.subviews.first(where: { $0 is ProgressView }) as? ProgressView {
			return view
		}
		
		let progressHeight: CGFloat = 2.5
		let navBarRect = self.navigationBar.bounds
		let progressFrame = CGRect(x: 0, y: navBarRect.height - progressHeight, width: navBarRect.width, height: progressHeight)
		let progressView = ProgressView(frame: progressFrame)
		progressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.navigationBar.addSubview(progressView)
		
		return progressView
	}
	
	func showProgress(duration: TimeInterval = 2, completion: ((Bool) -> ())? = nil) {
		showProgress(percentage: 100, duration: duration) { completed in
			self.hideProgress()
			completion?(completed)
		}
	}
	
	func showProgress(percentage: Double, duration: TimeInterval = 0.3, completion: ((Bool) -> ())? = nil) {
		let progressView = self.progressView
		UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
			progressView.progress = percentage / 100
		}, completion: completion)
	}
	
	func hideProgress(duration: TimeInterval = 0.5, completion: ((Bool) -> ())? = nil) {
		let progressView = self.progressView
		UIView.animate(withDuration: duration, animations: {
			progressView.alpha = 0
		}) { completed in
			progressView.removeFromSuperview()
			completion?(completed)
		}
	}
	
}
