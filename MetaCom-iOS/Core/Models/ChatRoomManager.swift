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
	private var chats: [ChatRoom] = []
	
	/// Currently displayed chat room.
	private weak var currentChatRoom: ChatRoom?
	
	/**
		Represents current chat room the user works with.
		Setting this property does nothing if the connection has been removed.
	*/
	public var currentChat: ChatRoom? {
		get {
			return currentChatRoom
		}
		set(chat) {
			
			guard let aChat = chat, chats.contains(aChat) else {
				return
			}
			
			currentChatRoom = aChat
		}
	}
	
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
	func addRoom(named name: String, completion: Completion? = nil) {
		
		let chat = ChatRoom(name: name, connection: connection)
		chat.join { (error) in
			
			defer {
				completion?(error)
			}
			
			guard error == nil else {
				return
			}
			
			self.currentChatRoom = chat
			self.chats.append(chat)
		}
	}
	
	/**
		Remove existing chatroom.
		- parameters:
			- name: chat name.
	*/
	func removeRoom(named name: String, completion: Completion? = nil) {
		
		guard let chat = getRoom(named: name) else {
			completion?(MCError(of: .noChat))
			return
		}
		
		removeRoom(chat, completion: completion)
	}
	
	/**
		Remove existing chatroom.
		- parameters:
			- chatRoom: chat room to remove.
	*/
	func removeRoom(_ chatRoom: ChatRoom, completion: Completion? = nil) {
		
		chatRoom.leave { error in
			
			defer {
				completion?(error)
			}
			
			guard let `error` = error, let localError = MCError(from: error), localError.errorCode != 31 else {
                self.chats.remove(chatRoom)
				return
			}
		}
	}
	
	/**
		Get chat by name.
		- parameters:
			- name: chat name.
	*/
	func getRoom(named name: String) -> ChatRoom? {
		
		guard let index = chats.index(where: { $0.name == name }) else {
			return nil
		}
		return chats[index]
	}
}
