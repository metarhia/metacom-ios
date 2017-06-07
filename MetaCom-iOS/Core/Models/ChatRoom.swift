//
//  ChatRoom.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

typealias Completion = (Error?) -> ()

/**
	A type representing a chat conversation.
*/
class ChatRoom {
	
	public let name: String
	fileprivate let connection: Connection
	fileprivate var receivers: Array<ChatRoomDelegate> = []
	
	/**
		Create a new `ChatRoom` instance.
		- parameters:
			- name: chat identifier.
			- connection: transport connection.
	*/
	init(name: String, connection: Connection) {
		
		self.name = name
		self.connection = connection
	}
	
	/**
		Join a particular chatroom on a server.
		- parameters:
			- completion: callback on completion.
	*/
	func join(completion: Completion?) {
		
		self.connection.call(Constants.interfaceName, "join", [name]) { (_, error) in
			
			defer {
				completion?(error)
			}
			
			guard error == nil else {
				return
			}
			
			self.addObservers()
		}
	}
	
	/**
		Leave a particular chatroom on a server.
		- parameters:
			- completion: callback on completion.
	*/
	func leave(completion: Completion?) {
		
		self.connection.call(Constants.interfaceName, "leave", [], { completion?($1) })
	}
	
	/**
		Send a message object via the current connection.
		- parameters:
			- message: sent message.
			- completion: callback on completion.
	*/
	func send(message: Message, completion: Completion?) {
		
		switch message.content {
		case .text(let text):
			connection.call(Constants.interfaceName, "send", [text], { completion?($1) })
		case .file(let data):
			// TODO: Send file
			break
		}
	}
	
	/**
		Create observers for the common events.
	*/
	private func addObservers() {
		
		let selectors = [
			Events.message : #selector(onReceiveMessage(_:)),
			Events.chatJoin : #selector(onJoinChat(_:)),
			Events.chatLeave : #selector(onLeaveChat(_:))
		]
		
		let notifications = selectors.map { pair -> (Notification.Name, Selector) in
			let event = Events.get(event: pair.key, for: self.name)
			return (Notification.Name(event), pair.value)
		}
		
		notifications.forEach { [weak self] (name, selector) in
			
			guard let this = self else {
				return
			}
			
			let center = NotificationCenter.default
			center.addObserver(this, selector: selector, name: name, object: this.connection)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		self.leave(completion: nil)
	}
}

extension ChatRoom {
	
	/**
		Receive a message and pass to receivers.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc fileprivate func onReceiveMessage(_ notification: Notification) {
		
		guard let event = notification.userInfo?[Constants.notificationObject] as? Event, let content = event.arguments.first as? String else {
			return
		}
		
		let message = Message(content: .text(content))
		receivers.forEach { $0.chatRoom(self, didReceive: message) }
	}
	
	/**
		Receive upon an interlocutor joining chat.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc fileprivate func onJoinChat(_ notification: Notification) {
		
		receivers.forEach { $0.chatRoomDidJoin(self) }
	}
	
	/**
		Receive upon an interlocutor leaving chat.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc fileprivate func onLeaveChat(_ notification: Notification) {
		
		receivers.forEach { $0.chatRoomDidLeave(self) }
	}
}

extension ChatRoom {
	
	/**
		Subscribe to message receiving.
		- parameters:
			- this: message receiver instance.
	*/
	func subscribe<Listener>(_ this: Listener) where Listener: ChatRoomDelegate & Equatable {
		
		guard !receivers.contains(where: { ($0 as! Listener) == this }) else {
			return
		}
		
		receivers.append(this)
	}
	
	/**
		Unsubscribe from message receiving.
		- parameters:
			- this: message receiver instance.
	*/
	func unsubscribe<Listener>(_ this: Listener) where Listener: ChatRoomDelegate & Equatable {
		
		guard let index = receivers.index(where: { ($0 as! Listener) == this } ) else {
			return
		}
		
		receivers.remove(at: index)
	}
}

extension ChatRoom: Equatable {
	
	public static func ==(lhs: ChatRoom, rhs: ChatRoom) -> Bool {
		return lhs.name == rhs.name && lhs.connection.config.host == rhs.connection.config.host
	}
}
