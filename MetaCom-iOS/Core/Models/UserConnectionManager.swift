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
	private(set) var userConnections: [UserConnection] = []
	
	/// Currently displayed connection.
	private var currentUserConnection: UserConnection?
	
	/**
		Represents current connection the user works with.
		Setting this property does nothing if the connection has been removed.
	*/
	public var currentConnection: UserConnection? {
		get {
			return currentUserConnection
		}
		set(connection) {
			
			guard let aConnection = connection, userConnections.contains(aConnection) else {
				if connection == nil {
					currentUserConnection = nil
				}
				return
			}
			
			currentUserConnection = aConnection
		}
	}
	
	/**
		Create new `UserConnectionManager` instance.
	*/
	private init() {
	}
	
	/**
		Establish new connection.
		- parameters: 
			- host: server host.
			- port: server port.
	*/
	func addConnection(host: String, port: Int) -> UserConnection {
		
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
	func removeConnection(_ connection: UserConnection) {
		
		userConnections.remove(connection)
	}
}
