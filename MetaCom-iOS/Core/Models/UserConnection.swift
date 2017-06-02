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
			- id: connection identifier.
			- host: server host.
			- port: server port.
			- secured: connection is secure.
			- credentials: user authentification credentials.
	*/
	init(id: Int, host: String, port: Int, secured: Bool = true, credentials: Credentials? = nil) {
		
		self.id = id
		
		let config = Configuration(host: host, port, secured, Constants.applicationName, credentials)
		self.config = config
		
		let connection = Connection(config: config, delegate: self)
		self.connection = connection
		
		chatManager = ChatRoomManager(connection: self.connection)
		fileManager = FileManager(self.connection)
		
		self.connection.connect()
	}
	
	deinit {
		// TODO: Close `connection`
	}
}

extension UserConnection: ConnectionDelegate {
	
	public func connection(_ connection: JSTP.Connection, didReceiveEvent event: JSTP.Event) {
		handle(received: event)
	}
	
	public func connectionDidDisconnect(_ connection: JSTP.Connection) {
		NotificationCenter.default.post(name: Notification.Name.MCConnectionLost, object: self)
	}
	
	public func connectionDidConnect(_ connection: JSTP.Connection) {
		NotificationCenter.default.post(name: Notification.Name.MCConnectionEstablished, object: self)
	}
	
	public func connection(_ connection: Connection, didFailWithError error: Error) {
		NotificationCenter.default.post(name: Notification.Name.MCConnectionDidFail, object: self, userInfo: ["error": error])
		NSLog("Connection #\(id) failed with error \(error.localizedDescription)")
	}
	
	func connectionShouldRestoreState(_ connection: Connection, callback: @escaping () -> Void) {
		callback()
	}
	
	private func handle(received event: Event) {
		
		// TODO: Current version includes only one chat instance at time, therefore it will be used with default identifier.
		let params = [Constants.notificationObject : event]
		let eventName = Events.get(event: event.name, for: Constants.roomDefault)
		let notification = Notification.Name(eventName)
		
		NotificationCenter.default.post(name: notification, object: self.connection, userInfo: params)
	}
}

extension UserConnection: Equatable {
	
	public static func ==(lhs: UserConnection, rhs: UserConnection) -> Bool {
		return  lhs.id == rhs.id
	}
}
