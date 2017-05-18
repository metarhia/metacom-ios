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
		Type of the concrete message.
	*/
	public enum MessageType: UInt {
		case text = 0, file
	}
	
	public let type: MessageType
	public let content: String
	public let isIncoming: Bool
	
	/**
		Construct a new `Message` instance.
		- parameters:
			- type: message type.
			- content: message contents.
	*/
	init(_ type: MessageType, _ content: String, _ isIncoming: Bool = true) {
		
		self.type = type
		self.content = content
		self.isIncoming = isIncoming
	}
}
