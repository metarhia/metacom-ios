//
//  ChatRoomManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a chat conversation manager.
*/
final class ChatRoomManager {
	
	public let connection: Connection
	private var chats: Array<ChatRoom> = []
	
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
	func add(id: String = Constants.roomDefault, completion: Callback? = nil) {
		
		let chat = ChatRoom(id, connection)
		chat.join { (_, error) in
			
			defer {
				completion?(nil, error)
			}
			
			guard error == nil else {
				return
			}
			
			self.chats.append(chat)
		}
	}
	
	/**
		Remove existing chatroom.
		- parameters:
			- id: chat name.
	*/
	func remove(_ id: String, completion: Callback? = nil) {
		
		guard let index = chats.index(where: { $0.id == id }) else {
			return
		}
		
		let chat = chats[index]
		chat.leave { (_, error) in
			
			defer {
				completion?(nil, error)
			}
			
			guard error == nil else {
				return
			}
			
			self.chats.remove(at: index)
		}
	}
	
	/**
		Get chat by id.
		- parameters:
			- id: chat name.
	*/
	func get(by id: String) -> ChatRoom? {
		
		return (chats.filter { $0.id == id }).first
	}
}
