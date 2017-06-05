//
//  UserConnection.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation
import JSTP

typealias Event = JSTP.Event
typealias Callback = JSTP.Callback
typealias Connection = JSTP.Connection
typealias Credentials = JSTP.Credentials
typealias Configuration = JSTP.Configuration
typealias ConnectionDelegate = JSTP.ConnectionDelegate

/**
	A type representing a user in the anonymous chat.
*/
final class UserConnection {
	
	private let config: Configuration!
	fileprivate var connection: Connection!
	
	private(set) var chatManager: ChatRoomManager!
	private(set) var fileManager: FileManager!
	
	public let id: Int
	
	public var host: String {
		return config.host
	}
	
	public var port: Int {
		return config.port
	}
	
	/**
		Create new `UserConnection` instance.
		- parameters:
			- identifier: connection identifier.
			- configuration: connection configuration.
	*/
	init(identifier: Int, configuration: Configuration) {

		id = identifier
		config = configuration
		connection = Connection(config: config, delegate: self)
		
		chatManager = ChatRoomManager(connection: connection)
		fileManager = FileManager(self.connection)
	}
	
	/**
		Connect to a `MetaCom` server.
		- parameters:
			- callback: block called on operation completion.
	*/
	func connect(with callback: @escaping (UserConnection, Error?) -> Void) {
		
		let queue = OperationQueue.current
		let center = NotificationCenter.default
		
		var didFailToken: NSObjectProtocol? = nil
		var didDisconnectToken: NSObjectProtocol? = nil
		
		/// Callback on operation completion.
		let completion: Callback = { [weak self] _, error in
			
			guard let this = self else {
				return
			}

			callback(this, error)
			didFailToken != nil ? center.removeObserver(didFailToken!) : ()
			didDisconnectToken != nil ? center.removeObserver(didDisconnectToken!) : ()
		}
		
		/// Block called if any transport related error occures.
		let block: (Notification) -> Void = {
			let error = $0.userInfo?["error"] as? Error ?? MCError(of: .connectionLost)
			completion(nil, error)
		}
		
		didFailToken = center.addObserver(forName: .MCConnectionDidFail, object: self, queue: queue, using: block)
		didDisconnectToken = center.addObserver(forName: .MCConnectionLost, object: self, queue: queue, using: block)
		
		connection.connect()
		connection.handshake(Constants.applicationName, completion)
	}
	
	deinit {
		// TODO: Close `connection`
		self.connection.disconnect()
	}
}

extension UserConnection: ConnectionDelegate {
	
	public func connection(_ connection: JSTP.Connection, didReceiveEvent event: JSTP.Event) {
		handle(received: event)
	}
	
	public func connectionDidDisconnect(_ connection: JSTP.Connection) {
		NotificationCenter.default.post(name: .MCConnectionLost, object: self)
	}
	
	public func connectionDidConnect(_ connection: JSTP.Connection) {
		NotificationCenter.default.post(name: .MCConnectionEstablished, object: self)
	}
	
	public func connection(_ connection: Connection, didFailWithError error: Error) {
		NotificationCenter.default.post(name: .MCConnectionDidFail, object: self, userInfo: ["error": error])
		NSLog("Connection #\(id) failed with error \(error.localizedDescription)")
	}
	
	func connectionShouldRestoreState(_ connection: Connection, callback: @escaping () -> Void) {
		callback()
	}
	
	private func handle(received event: Event) {
		
		let params = [Constants.notificationObject : event]
		let eventName = Events.get(event: event.name, for: chatManager.currentChat?.name ?? "")
		let notification = Notification.Name(eventName)
		
		NotificationCenter.default.post(name: notification, object: self.connection, userInfo: params)
	}
}

extension UserConnection: Equatable {
	
	public static func ==(lhs: UserConnection, rhs: UserConnection) -> Bool {
		return  lhs.id == rhs.id
	}
}
