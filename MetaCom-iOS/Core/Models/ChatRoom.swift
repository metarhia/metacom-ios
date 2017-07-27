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
			
		case .file(let data, let uti):
			sendFile(data, mimeType: FileManager.extractMimeType(from: uti))
			
		case .fileURL(let url):
			guard let data = try? Data(contentsOf: url) else {
				completion?(MCError(of: .fileFailed))
				return
			}
			
			sendFile(data, mimeType: FileManager.extractMimeType(from: url))
		}
	}
	
	/**
		Send a file via current connection.
		- parameters:
			- data: sent raw data
			- mimeType: data mime type.
			- completion: callback on completion.
	*/
	private func sendFile(_ data: Data, mimeType: String, completion: Completion? = nil) {
		
		let onTransferEnd = { [unowned self] (error: Error?) in
			
			guard error == nil else {
				completion?(error)
				return
			}
			
			self.connection.call(Constants.interfaceName, "endChatFileTransfer") { completion?($1) }
		}
		
		let onTransferStart = { [unowned self] (_: Any?, error: Error?) in
			
			guard error == nil else {
				completion?(error)
				return
			}
			
			FileManager.upload(data: data, via: self.connection, method: "sendFileChunkToChat", completion: onTransferEnd)
		}
		
		connection.call(Constants.interfaceName, "startChatFileTransfer", [mimeType], onTransferStart)
	}
	
	/**
		Create observers for the common events.
	*/
	private func addObservers() {
		
		let selectors: [Events : Selector] = [
			.message : #selector(onReceiveMessage(_:)),
			.chatJoin : #selector(onJoinChat(_:)),
			.chatLeave : #selector(onLeaveChat(_:)),
			.chatFileTransferStart : #selector(onChatFileTransferStart(_:))
		]
		
		let notifications = selectors.map { pair -> (event: Notification.Name, method: Selector) in
			let event = Events.name(ofEvent: pair.key)
			return (Notification.Name(event), pair.value)
		}
		notifications.forEach { [weak self] pair in
			
			guard let this = self else {
				return
			}
			
			let center = NotificationCenter.default
			center.addObserver(this, selector: pair.method, name: pair.event, object: this.connection)
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
	
	/**
		Receive upon chat interlocutor starts file transfer.
		- parameters:
			- notification: notification containing a message.
	*/
	@objc fileprivate func onChatFileTransferStart(_ notification: Notification) {
		
		guard let event = notification.userInfo?[Constants.notificationObject] as? Event else {
			return
		}
		
		let mimeType = event.arguments.first as? String ?? ""
		let fileExtension = FileManager.extractExtension(from: mimeType)
		
		let chunkDownloadName = Events.name(ofEvent: .chatFileTransferChunk)
		let fileDownloadName = Events.name(ofEvent: .chatFileTransferEnd)
		
		let chunkNotification = Notification.Name(chunkDownloadName)
		let fileNotification = Notification.Name(fileDownloadName)
		let notifications = (onChunkDownload: chunkNotification, onDownloadEnd: fileNotification)
		
		FileManager.download(listenTo: notifications, on: connection) { [unowned self] data, error in
	  
	  guard let data = data else {
		let fileError = error ?? MCError(of: .fileFailed)
		self.receivers.forEach { $0.chatRoom(self, didReceive: fileError) }
		return
	  }
	  
	  let message = Message(content: .file(data, type: fileExtension))
	  self.receivers.forEach { $0.chatRoom(self, didReceive: message) }
		}
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
		return lhs.name == rhs.name &&
			lhs.connection.config.host == rhs.connection.config.host &&
			lhs.connection.config.port == rhs.connection.config.port
	}
}
