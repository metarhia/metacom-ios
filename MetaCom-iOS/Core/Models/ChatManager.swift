//
//  ChatManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a chat conversation manager.
*/
final class ChatManager {
	
	public let connection: Connection
	private var chats: Array<Chat> = []
	
	/**
		Create new `ChatManager` instance.
		- parameters:
			- connection: transport connection.
	*/
	init(_ connection: Connection) {
		self.connection = connection
	}
	
	/**
		Add new chatroom.
		- parameters:
			- id: chat name.
			- completion: callback on completion.
	*/
	func add(_ id: String, completion: (Error?) -> Void) {
		
		let chat = Chat(id, connection)
		chats.append(chat)
	}
	
	/**
		Remove existing chatroom.
		- parameters:
			- id: chat name.
	*/
	func remove(_ id: String) {
		
		guard let index = chats.index(where: { $0.id == id }) else {
			return
		}
		
		chats.remove(at: index)
	}
	
	/**
		Get chat by id.
		- parameters:
			- id: chat name.
	*/
	func get(by id: String) -> Chat? {
		
		return (chats.filter { $0.id == id }).first
	}
}
