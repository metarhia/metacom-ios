//
//  Chat.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a chat conversation.
*/
class Chat {
	
	public let id: String
	public let connection: Connection
	fileprivate var receivers: Array<MessageReceiver> = []
	
	/**
		Create a new `Chat` instance.
		- parameters:
			- id: chat identifier.
			- connection: transport connection.
	*/
	init(_ id: String, _ connection: Connection) {
		
		self.id = id
		self.connection = connection
	}
	
	/**
		Send a message object via the current connection.
		- parameters:
			- message: sent message.
			- completion: callback on completion.
	*/
	func send(_ message: Message, completion: (Error?) -> Void) {
		
	}
}

extension Chat {
	
	/**
		Subscribe to message receiving.
		- parameters:
			- this: message receiver instance.
	*/
	func subscribe<Listener>(_ this: Listener) where Listener: MessageReceiver & Equatable {
		
		receivers.append(this)
	}
	
	/**
		Unsubscribe from message receiving.
		- parameters:
			- this: message receiver instance.
	*/
	func unsubscribe<Listener>(_ this: Listener) where Listener: MessageReceiver & Equatable {
		
		guard let index = receivers.index(where: { ($0 as! Listener) == this } ) else {
			return
		}
		
		receivers.remove(at: index)
	}
}
