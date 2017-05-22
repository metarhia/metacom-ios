//
//  JSQMessage+InitFromMessage.swift
//  MetaCom-iOS
//
//  Created by iKing on 22.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation
import JSQMessagesViewController

extension JSQMessage {
	
	convenience init(message: Message) {
		// TODO: Handle messages with file content
		let id = message.isIncoming ? Constants.Chat.incomingSenderId : Constants.Chat.outcomingSenderId
		let text: String
		switch message.content {
		case .text(let value):
			text = value
		default:
			text = "There is no text. Maybe file, but files are not handled yet."
		}
		self.init(senderId: id, displayName: "", text: text)
	}
}
