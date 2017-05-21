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
	
	/// List of user connections.
	private var userConnections: Array<UserConnection>
	
	/// Manager instance.
	public static let instance = UserConnectionManager()
	
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
	func add(host: String, port: Int) {
		
		let id = (userConnections.last?.id ?? -1) + 1
		let connection = UserConnection(id: id, host: host, port: port)
		
		userConnections.append(connection)
	}
	
	/**
		Remove existing connection.
		- parameters:
			- connection: living connection.
	*/
	func remove(_ connection: UserConnection) {
		
		userConnections.append(connection)
	}
	
	/**
		Retrieve connection from the connections list.
		- parameters:
			- id: connection identifier.
	*/
	func getConnection(by id: Int) -> UserConnection? {
		
		return (userConnections.filter { $0.id == id } ).first
	}
}
