//
//  ChatRoom.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation
import JSTP

/**
	A type representing a chat conversation.
*/
class ChatRoom {
	
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
		Join a particular chatroom on a server.
		- parameters:
			- completion: callback on completion.
	*/
	func join(_ completion: Callback?) {
		
		self.connection.call(Constants.interfaceName, "join", [id]) { (_, error) in
			
			defer {
				completion?(nil, error)
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
	func leave(_ completion: Callback?) {
		
		self.connection.call(Constants.interfaceName, "leave", [], completion)
	}
	
	/**
		Send a message object via the current connection.
		- parameters:
			- message: sent message.
			- completion: callback on completion.
	*/
	func send(_ message: String, completion: Callback?) {
		
		connection.call(Constants.interfaceName, "send", [message], completion)
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
			let event = Events.get(event: pair.key, for: self.id)
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
}

extension ChatRoom {
	
	/**
		Receive a message and pass to receivers.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc func onReceiveMessage(_ notification: Notification) {
		
		guard let content = notification.userInfo?[Constants.notificationObject] as? String else {
			return
		}
		
		let message = Message(content: Message.Content.text(content))
		receivers.forEach { $0.didReceive(message) }
	}
	
	/**
		Receive upon an interlocutor joining chat.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc func onJoinChat(_ notification: Notification) {
		
		receivers.forEach { $0.didJoin() }
	}
	
	/**
		Receive upon an interlocutor leaving chat.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc func onLeaveChat(_ notification: Notification) {
		
		receivers.forEach { $0.didLeave() }
	}
}

extension ChatRoom {
	
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
