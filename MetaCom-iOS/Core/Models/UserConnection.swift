//
//  UserConnection.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a user in the anonymous chat.
*/
final class UserConnection {
	
	public let id: Int
	public let connection: Connection
	public let chatManager: ChatManager
	public let fileManager: FileManager
	
	/**
		Create new `UserConnection` instance.
		- parameters:
			- id: connection identifier.
			- connection: concrete transport connection.
	*/
	init(_ id: Int, _ connection: Connection) {
		
		self.id = id
		self.connection = connection
		
		chatManager = ChatManager(connection)
		fileManager = FileManager(connection)
	}
}
