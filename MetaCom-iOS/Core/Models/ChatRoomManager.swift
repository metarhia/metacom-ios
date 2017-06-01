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
	
	private let connection: Connection
	private var chats: Array<ChatRoom> = []
	
	/**
		Create new `ChatManager` instance.
		- parameters:
			- connection: transport connection.
	*/
	init(connection: Connection) {
		self.connection = connection
	}
	
	/**
		Add new chatroom.
		- parameters:
			- name: chat name.
			- completion: callback on completion.
	*/
	func addRoom(named name: String = Constants.roomDefault, completion: Completion? = nil) {
		
		let chat = ChatRoom(name: name, connection: connection)
		chat.join { (error) in
			
			defer {
				completion?(error)
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
			- name: chat name.
	*/
	func removeRoom(named name: String, completion: Completion? = nil) {
		
		guard let index = chats.index(where: { $0.name == name }) else {
			return
		}
		
		let chat = chats[index]
		chat.leave { (error) in
			
			defer {
				completion?(error)
			}
			
			guard error == nil else {
				return
			}
			
			self.chats.remove(at: index)
		}
	}
	
	/**
		Get chat by name.
		- parameters:
			- name: chat name.
	*/
	func getRoom(named name: String) -> ChatRoom? {
		
		return (chats.filter { $0.name == name }).first
	}
}
