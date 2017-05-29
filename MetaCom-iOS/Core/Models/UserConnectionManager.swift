//
//  UserConnectionManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a manager for user connections to various server hosts and ports.
*/
final class UserConnectionManager {
	
	/// Manager instance.
	public static let instance = UserConnectionManager()
	
	/// List of user connections.
	private(set) var userConnections: Array<UserConnection>
	
	/// Current displayed connection.
	private(set) var currentConnection: UserConnection?
	
	/**
		Create new `UserConnectionManager` instance.
	*/
	private init() {
 		userConnections = []
	}
	
	/**
		Establish new connection.
		- parameters: 
			- host: server host.
			- port: server port.
	*/
	func add(host: String, port: Int) -> UserConnection {
		
		let id = (userConnections.last?.id ?? -1) + 1
		let connection = UserConnection(id: id, host: host, port: port)
		
		userConnections.append(connection)
		
		return connection
	}
	
	/**
		Remove existing connection.
		- parameters:
			- connection: living connection.
	*/
	func remove(_ connection: UserConnection) {
		
		if let index = userConnections.index(of: connection) {
			userConnections.remove(at: index)
		}
	}
	
	/**
		Set connection as the current connection the user works with.
		This method does nothing if the connection has been removed.
		- parameters:
			- connection: living connection.
	*/
	func setCurrent(connection: UserConnection?) {
		
		guard let aConnection = connection, userConnections.contains(aConnection) else {
			
			if connection == nil {
				currentConnection = nil
			}
			return
		}
		
		currentConnection = aConnection
	}
}
