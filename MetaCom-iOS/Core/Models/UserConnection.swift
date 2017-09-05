//
//  UserConnection.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import ReachabilitySwift
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
	private let reachability: Reachability!
	fileprivate var connection: Connection!
	
	private(set) var chatManager: ChatRoomManager!
	private(set) var fileManager: FileManager!
	
	public let id: Int
	public var isActive: Bool = false
	public var currentReachability: Reachability.NetworkStatus? = nil {
		didSet {
			oldValue == .notReachable ? reconnect() : ()
		}
	}
	
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
		reachability = Reachability()
		connection = Connection(config: config, delegate: self)
		
		chatManager = ChatRoomManager(connection: connection)
		fileManager = FileManager(connection: connection)
		
		let onStatusChanged: Reachability.NetworkUnreachable? = { [unowned self] status in
			self.currentReachability = status.currentReachabilityStatus
		}
		
		reachability.whenReachable = onStatusChanged
		reachability.whenUnreachable = onStatusChanged
	}
	
	/**
		Connect to a `MetaCom` server.
		- parameters:
			- callback: block called on operation completion.
	*/
	func connect(with callback: @escaping (Error?) -> Void) {
		
		let queue = OperationQueue.current
		let center = NotificationCenter.default
		
		var tokens = [NSObjectProtocol?]()
		
		/// Callback on operation completion.
		let completion: Callback = { [unowned self] _, serverError in
			
			tokens.forEach(center.removeObserver)
			tokens.removeAll()
			
			let didInitReachability: Void? = try? self.reachability.startNotifier()
			let error = (didInitReachability != nil) ? nil : MCError(of: .connectionLost)
			
			callback(serverError ?? error)
		}
		
		/// Block called if any transport related error occures.
		let errorHandler: (Notification) -> Void = {
			let error = $0.userInfo?["error"] as? Error ?? MCError(of: .connectionLost)
			completion(nil, error)
		}
		
		let t1 = center.addObserver(forName: .MCConnectionDidFail, object: connection, queue: queue, using: errorHandler)
		let t2 = center.addObserver(forName: .MCConnectionLost, object: connection, queue: queue, using: errorHandler)
		let t3 = center.addObserver(forName: .UIApplicationDidEnterBackground, object: connection, queue: queue, using: errorHandler)
		
		tokens.append(contentsOf: [t1, t2, t3])
		
		connection.connect()
		connection.handshake(Constants.applicationName, completion)
	}
	
	/**
		Attempt to reconnect to a `MetaCom` server.
	*/
	func reconnect(with callback: ((Error?) -> Void)? = nil) {
		
		connection.reconnect(config: config)
		connection.handshake(Constants.applicationName) { [unowned self] _, error in
			let name: Notification.Name = (error != nil) ? .MCConnectionDidFail : .MCConnectionRestored
			NotificationCenter.default.post(name: name, object: self.connection)
			
			callback?(error)
		}
	}
	
	/**
		Disconnect from a `MetaCom` server.
	*/
	func disconnect() {
		
		NotificationCenter.default.removeObserver(self, name: nil, object: connection)
		connection.disconnect()
		connection = nil
	}
	
	deinit {
		
		NotificationCenter.default.removeObserver(self, name: nil, object: nil)
		disconnect()
	}
}

extension UserConnection: ConnectionDelegate {
	
	public func connection(_ connection: JSTP.Connection, didReceiveEvent event: JSTP.Event) {
		handle(received: event)
	}
	
	public func connectionDidDisconnect(_ connection: JSTP.Connection) {
		NotificationCenter.default.post(name: .MCConnectionLost, object: connection)
	}
	
	public func connectionDidConnect(_ connection: JSTP.Connection) {
		isActive = true
		
		let center = NotificationCenter.default
		center.post(name: .MCConnectionEstablished, object: connection)
	}
	
	public func connection(_ connection: Connection, didFailWithError error: Error) {
		
		guard isActive else {
			return
		}
		
		isActive = false
		NotificationCenter.default.post(name: .MCConnectionDidFail, object: connection, userInfo: ["error": error])
		
		reconnect()
		Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
			
			guard let isEstablished = self?.isActive, !isEstablished else {
				return timer.invalidate()
			}
			
			self?.reconnect { error in
				
				guard error == nil else {
					return
				}
				
				timer.invalidate()
			}
		}
		
		NSLog("Connection #\(id) failed with error \(error.localizedDescription)")
	}
	
	func connectionShouldRestoreState(_ connection: JSTP.Connection, callback: @escaping () -> Void) {
		callback()
	}
	
	private func handle(received event: Event) {
		
		let params = [Constants.notificationObject : event]
		let eventName = Events.name(ofEvent: event.name)
		let notification = Notification.Name(eventName)
		
		NotificationCenter.default.post(name: notification, object: connection, userInfo: params)
	}
}

extension UserConnection: Equatable {
	
	public static func ==(lhs: UserConnection, rhs: UserConnection) -> Bool {
		return lhs.id == rhs.id
	}
}
