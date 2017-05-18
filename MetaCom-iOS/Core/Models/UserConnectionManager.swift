//
//  UserConnectionManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

// MARK: - Stub.
protocol Connection { }

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
			- completion: callback on completion.
	*/
	func add(_ host: String, _ port: Int, _ completion: (Error?) -> Void) {
		
		let id = (userConnections.last?.id ?? -1) + 1
		
		// TODO: Implement JSTP transport
		let transportConnection: (Any)? = nil
		let connection = UserConnection(id, transportConnection as! Connection)
		
		userConnections.append(connection)
		completion(nil)
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
