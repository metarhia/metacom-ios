//
//  SystemMessagesBubbleImage.swift
//  MetaCom-iOS
//
//  Created by iKing on 16.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import JSQMessagesViewController

class SystemMessagesBubbleImage: NSObject, JSQMessageBubbleImageDataSource {
	
	func messageBubbleImage() -> UIImage! {
		return UIImage()
	}
	
	func messageBubbleHighlightedImage() -> UIImage! {
		return UIImage()
	}
}
