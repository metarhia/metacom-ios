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
	
	var data: Data {
		didSet {
			cachedView = nil
		}
	}
	
	var isLoading: Bool = false {
		didSet {
			cachedView?.isLoading = isLoading
		}
	}
	
	// MARK: - Initialization
	
	init(data: Data, maskAsOutgoing outgoing: Bool) {
		self.data = data
		
		super.init(maskAsOutgoing: outgoing)
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
		view.backgroundColor = isOutgoing ? .jsq_messageBubbleBlue() : .jsq_messageBubbleLightGray()
		view.tintColor = isOutgoing ? .white : UIColor.black.withAlphaComponent(0.7)
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
		
		return view
	}
	
	override func mediaViewDisplaySize() -> CGSize {
		return CGSize(width: 78, height: 90)
	}
	
	// MARK: - NSObject
	
	override var hash: Int {
		return super.hash ^ data.hashValue
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.data = aDecoder.decodeObject(forKey: NSStringFromSelector(#selector(getter: data))) as? Data ?? Data()
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(data, forKey: NSStringFromSelector(#selector(getter: data)))
	}
}
