//
//  ChatRoomDelegate.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 18.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	Protocol that handles interaction with chat room.
*/
protocol ChatRoomDelegate: class {
	
	func chatRoomDidJoin(_ chatRoom: ChatRoom)
	func chatRoomDidLeave(_ chatRoom: ChatRoom)
	func chatRoom(_ chatRoom: ChatRoom, didReceive message: Message)
	func chatRoom(_ chatRoom: ChatRoom, didReceive error: Error)
	func chatRoom(_ chatRoom: ChatRoom, connectionDidChange connected: Bool)
}

extension ChatRoomDelegate {
	
	func chatRoomDidJoin(_ chatRoom: ChatRoom) { }
	func chatRoomDidLeave(_ chatRoom: ChatRoom) { }
	func chatRoom(_ chatRoom: ChatRoom, didReceive message: Message) { }
	func chatRoom(_ chatRoom: ChatRoom, didReceive error: Error) { }
	func chatRoom(_ chatRoom: ChatRoom, connectionDidChange connected: Bool) { }
}
