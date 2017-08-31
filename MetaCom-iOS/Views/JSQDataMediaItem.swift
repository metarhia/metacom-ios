//
//  JSQDataMediaItem.swift
//  MetaCom-iOS
//
//  Created by iKing on 26.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class JSQDataMediaItem: JSQMediaItem {
	
	private var cachedView: DataMediaView?
	
	var isLoading: Bool = false {
		didSet {
			cachedView?.isLoading = isLoading
		}
	}
	
	func setLoading(_ loading: Bool, animated: Bool = true) {
		UIView.animate(withDuration: animated ? 0.3 : 0) {
			self.isLoading = loading
		}
	}
	
	var isFailed: Bool = false {
		didSet {
			updateBackground()
		}
	}
	
	private func updateBackground() {
		let color: UIColor
		if appliesMediaViewMaskAsOutgoing {
			color = isFailed ? .messageBubbleFailed : .messageBubbleOutgoing
		} else {
			color = .messageBubbleIncoming
		}
		cachedView?.backgroundColor = color
	}
	
	// MARK: - JSQMediaItem
	
	override func clearCachedMediaViews() {
		super.clearCachedMediaViews()
		cachedView = nil
	}
	
	override var appliesMediaViewMaskAsOutgoing: Bool {
		didSet {
			cachedView = nil
		}
	}
	
	override func mediaView() -> UIView! {
		if let view = cachedView {
			return view
		}
		
		let isOutgoing = appliesMediaViewMaskAsOutgoing
		let view = DataMediaView(frame: CGRect(origin: .zero, size: mediaViewDisplaySize()))
		view.tintColor = isOutgoing ? UIColor.black : UIColor.white
		view.clipsToBounds = true
		view.isLoading = isLoading
		JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: view, isOutgoing: isOutgoing)
		
		// A bit of magic to center file icon after adding tail to a bubble
		if isOutgoing {
			view.insets.right = 4
		} else {
			view.insets.left = 8
		}
		
		cachedView = view
		
		updateBackground()
		
		return view
	}
	
	override func mediaViewDisplaySize() -> CGSize {
		return CGSize(width: 78, height: 90)
	}
	
}
