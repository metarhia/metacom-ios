//
//  ChatRoom.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

typealias Completion = (Error?) -> ()
typealias FileUpload = (data: Data, mimeType: String, completion: Completion?)

/**
	A type representing a chat conversation.
*/
class ChatRoom {
	
	public let name: String
	private(set) var isEmpty: Bool
	fileprivate let connection: Connection
	fileprivate var filesQueue: Array<FileUpload> = []
	fileprivate var receivers: Array<ChatRoomDelegate> = []
	fileprivate var observerTokens: Array<NSObjectProtocol> = []
	
	fileprivate var hasInterlocutor: Bool {
		set {
			isEmpty = !newValue
		}
		get {
			return !isEmpty
		}
	}
	
	/**
		Create a new `ChatRoom` instance.
		- parameters:
			- name: chat identifier.
			- connection: transport connection.
	*/
	init(name: String, connection: Connection) {
		
		self.name = name
		self.isEmpty = true
		self.connection = connection
		
		self.addObservers()
	}
	
	/**
		Join a particular chatroom on a server.
		- parameters:
			- completion: callback on completion.
	*/
	func join(completion: Completion?) {
		
		self.connection.cacheCall(Constants.interfaceName, "join", [name]) { values, error in
			
			defer {
				completion?(error)
			}
			
			guard error == nil else {
				return
			}
			
			let hasInterlocutor = values?.first as? Bool ?? false
			self.hasInterlocutor = hasInterlocutor
		}
	}
	
	/**
		Leave a particular chatroom on a server.
		- parameters:
			- completion: callback on completion.
	*/
	func leave(completion: Completion?) {
		
		let deinitHandler: Callback? = { [unowned self] _, error in
			
			NotificationCenter.default.removeObserver(self)
			
			self.observerTokens.forEach(NotificationCenter.default.removeObserver(_:))
			self.observerTokens.removeAll()
			self.filesQueue.removeAll()
			self.receivers.removeAll()
			
			completion?(error)
		}
		
		connection.cacheCall(Constants.interfaceName, "leave", [], deinitHandler)
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
			connection.cacheCall(Constants.interfaceName, "send", [text], { completion?($1) })
			
		case .file(let data, let uti):
			sendFile(data, mimeType: FileManager.extractMimeType(from: uti), completion: completion)
			
		case .fileURL(let url):
			guard let data = try? Data(contentsOf: url) else {
				completion?(MCError(of: .fileFailed))
				return
			}
			
			sendFile(data, mimeType: FileManager.extractMimeType(from: url), completion: completion)
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
		
		var loadFromQueue: (() -> ())?
		
		let clearCompletion: Completion? = { [unowned self] (error: Error?) in
			
			let completionHandler = self.filesQueue.removeFirst().completion
			
			defer {
				completionHandler?(error)
			}
			
			guard !self.filesQueue.isEmpty else {
				return
			}
			
			loadFromQueue?()
		}
		
		let onTransferEnd = { [unowned self] (error: Error?) in
			
			guard error == nil else {
				clearCompletion?(error)
				return
			}
			
			self.connection.cacheCall(Constants.interfaceName, "endChatFileTransfer", []) { clearCompletion?($1) }
		}
		
		let onTransferStart = { [unowned self] (_: Any?, error: Error?) in
			
			guard error == nil else {
				clearCompletion?(error)
				return
			}
			
			guard let file = self.filesQueue.first?.data else {
				clearCompletion?(MCError(of: .fileFailed))
				return
			}
			
			FileManager.upload(data: file, via: self.connection, method: "sendFileChunkToChat", completion: onTransferEnd)
		}
		
		loadFromQueue = { [weak self] in
			
			guard let type = self?.filesQueue.first?.mimeType else {
				clearCompletion?(MCError(of: .fileFailed))
				return
			}
			
			self?.connection.cacheCall(Constants.interfaceName, "startChatFileTransfer", [type], onTransferStart)
		}
		
		let fileUpload: FileUpload = (data: data, mimeType: mimeType, completion: completion)
		
		if filesQueue.isEmpty {
			filesQueue.append(fileUpload)
			loadFromQueue?()
		} else {
			filesQueue.append(fileUpload)
		}
	}
	
	/**
		Create observers for the common events.
	*/
	private func addObservers() {
		
		let selectors: [Events : (Notification) -> ()] = [
			.message : onReceiveMessage(_:),
			.chatJoin : onJoinChat(_:),
			.chatLeave : onLeaveChat(_:),
			.chatFileTransferStart : onChatFileTransferStart(_:)
		]
		
		let systemSelectors: [Notification.Name : (Notification) -> ()] = [
			.MCConnectionDidFail : onConnectionFailed(_:),
			.MCConnectionRestored : onConnectionRestored(_:)
		]
		
		let notifications = selectors.map { pair -> (event: Notification.Name, method: (Notification) -> ()) in
			let event = Events.name(ofEvent: pair.key)
			return (Notification.Name(event), pair.value)
		}
		
		let systemNotifications = systemSelectors.map { (event: $0.key, method: $0.value) }
		
		(notifications + systemNotifications).forEach { [weak self] pair in
			
			guard let this = self else {
				return
			}
			
			let center = NotificationCenter.default
			let token = center.addObserver(forName: pair.event, object: this.connection, queue: nil, using: pair.method)
			self?.observerTokens.append(token)
		}
	}
}

extension ChatRoom {
	
	/**
		Receive a message and pass to receivers.
		- parameters:
			- notification: notification containing a message.
	*/
	fileprivate func onReceiveMessage(_ notification: Notification) {
		
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
	fileprivate func onJoinChat(_ notification: Notification) {
		
		hasInterlocutor = true
		receivers.forEach { $0.chatRoomDidJoin(self) }
	}
	
	/**
		Receive upon an interlocutor leaving chat.
		- parameters:
			- notification: notification containing a message.
	*/
	fileprivate func onLeaveChat(_ notification: Notification) {
		
		hasInterlocutor = false
		receivers.forEach { $0.chatRoomDidLeave(self) }
	}
	
	/**
		Receive upon chat interlocutor starts file transfer.
		- parameters:
			- notification: notification containing a message.
	*/
	fileprivate func onChatFileTransferStart(_ notification: Notification) {
		
		guard let event = notification.userInfo?[Constants.notificationObject] as? Event else {
			return
		}
		
		let mimeType = event.arguments.first as? String ?? ""
		let fileUTI = FileManager.extractUTI(from: mimeType)
		
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
			
			let message = Message(content: .file(data, uti: fileUTI))
			self.receivers.forEach { $0.chatRoom(self, didReceive: message) }
		}
	}
	
	/**
		Receive upon connection lost.
		- parameters:
			- notification: notification containing a message.
	*/
	fileprivate func onConnectionFailed(_ notification: Notification) {
		self.filesQueue.removeAll()
		self.receivers.forEach { $0.chatRoom(self, connectionDidChange: false) }
	}
	
	/**
		Receive upon connection restored.
		- parameters:
			- notification: notification containing a message.
	*/
	fileprivate func onConnectionRestored(_ notification: Notification) {
		
		var onJoin: Completion?
		onJoin = { [unowned self] error in
			
			guard error == nil else {
				return self.join(completion: onJoin)
			}
			
			self.receivers.forEach { $0.chatRoom(self, connectionDidChange: true) }
		}
		
		join(completion: onJoin)
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
