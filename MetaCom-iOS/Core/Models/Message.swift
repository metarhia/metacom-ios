//
//  Message.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 18.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a chat message.
*/
class Message {
	
	/**
		`Message`'s content.
	*/
	public enum Content {
		case text(String)
		case file(Data, uti: String?)
		case fileURL(URL)
	}
	
	public let content: Content
	public let isIncoming: Bool
	
	/**
		Construct a new `Message` instance.
		- parameters:
			- type: message type.
			- content: message contents.
	*/
	init(content: Content, incoming: Bool = true) {
		
		self.content = content
		self.isIncoming = incoming
	}
}

