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
	
	private static let recentRemoteKey = "recent-remote"
	private static let needReconnectKey = "need-reconnect"
	
	/// Manager instance.
	public static let instance = UserConnectionManager()
	
	/// List of user connections.
	private(set) var userConnections: [UserConnection] = []
	
	/// Currently displayed connection.
	private weak var currentUserConnection: UserConnection? {
		didSet {
			needReconnect = currentUserConnection != nil
		}
	}
	
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
		Represents parameters of most recent successful connection.
	*/
	private(set) var recentRemote: Remote? {
		set {
			if let remote = newValue {
				UserDefaults.standard.set(remote.connectionString, forKey: UserConnectionManager.recentRemoteKey)
			} else {
				UserDefaults.standard.removeObject(forKey: UserConnectionManager.recentRemoteKey)
			}
		}
		get {
			if let connectionString = UserDefaults.standard.string(forKey: UserConnectionManager.recentRemoteKey) {
				return Remote(connectionString: connectionString)
			}
			return nil
		}
	}
	
	/**
		Need restore the previous connection.
	*/
	private(set) var needReconnect: Bool {
		set {
			UserDefaults.standard.set(newValue, forKey: UserConnectionManager.needReconnectKey)
		}
		get {
			
			return UserDefaults.standard.bool(forKey: UserConnectionManager.needReconnectKey)
		}
	}
	
	/**
		Create new `UserConnectionManager` instance.
	*/
	private init() { }
	
	/**
		Establish new connection.
		- parameters:
			- remote: specifies destination's `host:port`.
			- callback: called on completion.
	*/
	func addConnection(remote: Remote, callback: @escaping (UserConnection?) -> Void) {
		
		let id = (userConnections.last?.id ?? -1) + 1
		let config = Configuration(host: remote.host, remote.port, true, Constants.applicationName, nil)
		let connection = UserConnection(identifier: id, configuration: config)
		
		let completion: (Error?) -> Void = { [weak self, unowned connection] error in
			
			guard error == nil else {
				self?.userConnections.remove(connection)
				return callback(nil)
			}
			
			callback(connection)
			self?.recentRemote = remote
			RemotesManager.shared.addRemote(remote)
		}
		
		needReconnect = false
		userConnections.append(connection)
		connection.connect(with: completion)
	}
	
	/**
		Establish new connection.
		- parameters:
			- host: server host.
			- port: server port.
			- callback: called on completion.
	*/
	func addConnection(host: String, port: Int, callback: @escaping (UserConnection?) -> Void) {
		addConnection(remote: Remote(host: host, port: port), callback: callback)
	}
	
	/**
		Remove existing connection.
		- parameters:
			- connection: living connection.
	*/
	func removeConnection(_ connection: UserConnection) {
		if connection == currentUserConnection {
			currentUserConnection = nil
		}
		userConnections.remove(connection)
	}
}
