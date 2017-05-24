//
//  UIButton+ActivityIndicator.swift
//  MetaCom-iOS
//
//  Created by Andrew Visotskyy on 21.02.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import ObjectiveC

extension UIButton {
	
	private struct AssociatedKeys {
		static var cachedSubviews = "button.cachedSubviews"
		static var activityIndicator = "button.activityIndicator"
		static var isActivityIndicatorVisible = "button.isActivityIndicatorVisible"
	}
	
	private var activityIndicator: UIActivityIndicatorView? {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.activityIndicator) as? UIActivityIndicatorView
		}
		set {
			guard newValue != nil else {
				return
			}
			objc_setAssociatedObject(self, &AssociatedKeys.activityIndicator, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	private var cachedSubviews: [UIView] {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.cachedSubviews) as? [UIView] ?? []
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.cachedSubviews, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	private func showActivityIndicator() {
		subviews.forEach { view in
			cachedSubviews.append(view)
			view.removeFromSuperview()
		}
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		activityIndicator?.frame = bounds
		activityIndicator?.startAnimating()
		addSubview(activityIndicator!)
	}
	
	private func hideActivityIndicator() {
		cachedSubviews.forEach(self.addSubview)
		cachedSubviews.removeAll()
		activityIndicator?.stopAnimating()
		activityIndicator?.removeFromSuperview()
	}
	
	// MARK: -
	
	public var isActivityIndicatorVisible: Bool {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.isActivityIndicatorVisible) as? Bool ?? false
		}
		set {
			guard isActivityIndicatorVisible != newValue else {
				return
			}
			objc_setAssociatedObject(self, &AssociatedKeys.isActivityIndicatorVisible, newValue, .OBJC_ASSOCIATION_RETAIN)
			newValue ? showActivityIndicator() : hideActivityIndicator()
		}
	}
	
}
