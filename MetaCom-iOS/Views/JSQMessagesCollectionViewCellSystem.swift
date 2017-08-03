//
//  JSQMessagesCollectionViewCellSystem.swift
//  MetaCom-iOS
//
//  Created by iKing on 16.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import JSQMessagesViewController

class JSQMessagesCollectionViewCellSystem: JSQMessagesCollectionViewCell {
	
	@IBOutlet weak var textLabel: UILabel!
	
	var text: String? {
		get {
			return textLabel.text
		}
		set {
			textLabel.text = newValue
		}
	}
	
	override class func nib() -> UINib {
		return UINib(nibName: "JSQMessagesCollectionViewCellSystem", bundle: Bundle(for: JSQMessagesCollectionViewCellSystem.self))
	}
}
