//
//  ActivityButton.swift
//  MetaCom-iOS
//
//  Created by iKing on 27.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIControlState: Hashable {
	
	public var hashValue: Int {
		return Int(rawValue)
	}
}

private extension UIControlState {
	
	static var enumerated: [UIControlState] = [.normal, .highlighted, .disabled, .selected, .focused]
}

class ActivityButton: UIButton {
	
	private struct ButtonContent {
		var title: String?
		var attributedTitle: NSAttributedString?
		var image: UIImage?
	}
	
	private var storedStates: [UIControlState: ButtonContent] = [:]
	
	private weak var activityIndicator: UIActivityIndicatorView!
	
	override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		let activityIndicator = UIActivityIndicatorView(frame: self.bounds)
		activityIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		activityIndicator.activityIndicatorViewStyle = .white
		activityIndicator.hidesWhenStopped = true
		self.addSubview(activityIndicator)
		self.activityIndicator = activityIndicator
	}
	
	var activityIndicatorStyle: UIActivityIndicatorViewStyle {
		get {
			return activityIndicator.activityIndicatorViewStyle
		}
		set {
			activityIndicator.activityIndicatorViewStyle = newValue
		}
	}
	
	var isActivityIndicatorVisible: Bool = false {
		willSet {
			guard isActivityIndicatorVisible != newValue else {
				return
			}
			
			if newValue {
				storeStates()
				clearContent()
				activityIndicator.startAnimating()
			}
		}
		didSet {
			guard isActivityIndicatorVisible != oldValue else {
				return
			}
			
			if !isActivityIndicatorVisible {
				restoreStates()
				activityIndicator.stopAnimating()
			}
		}
	}
	
	override func setTitle(_ title: String?, for state: UIControlState) {
		if isActivityIndicatorVisible {
			var content = storedStates[state] ?? ButtonContent()
			content.title = title
			storedStates[state] = content
		} else {
			super.setTitle(title, for: state)
		}
	}
	
	override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControlState) {
		if isActivityIndicatorVisible {
			var content = storedStates[state] ?? ButtonContent()
			content.attributedTitle = title
			storedStates[state] = content
		} else {
			super.setAttributedTitle(title, for: state)
		}
	}
	
	override func setImage(_ image: UIImage?, for state: UIControlState) {
		if isActivityIndicatorVisible {
			var content = storedStates[state] ?? ButtonContent()
			content.image = image
			storedStates[state] = content
		} else {
			super.setImage(image, for: state)
		}
	}
	
	private func storeStates() {
		for state in UIControlState.enumerated {
			storedStates[state] = content(for: state)
		}
	}
	
	private func restoreStates() {
		for (state, content) in storedStates {
			setContent(content, for: state)
		}
	}
	
	private func clearContent() {
		for state in UIControlState.enumerated {
			setContent(ButtonContent(), for: state)
		}
	}
	
	private func content(for state: UIControlState) -> ButtonContent {
		var content = ButtonContent()
		content.title = title(for: state)
		content.attributedTitle = attributedTitle(for: state)
		content.image = image(for: state)
		return content
	}
	
	private func setContent(_ content: ButtonContent, for state: UIControlState) {
		setTitle(content.title, for: state)
		setAttributedTitle(content.attributedTitle, for: state)
		setImage(content.image, for: state)
	}
	
}
