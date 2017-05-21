//
//  Events.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 20.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

struct Events {
	
	/// Emitted when another user joins current.
	static let chatJoin = "chatJoin"
	
	/// Emitted when chat interlocutor leaves the chat.
	static let chatLeave = "chatLeave"
	
	/// Emitted when chat interlocutor sends a message.
	static let message = "message"
	
	/// Emitted when chat interlocutor sends file chunk.
	static let chatFileTransferChunk = "chatFileTransferChunk"
	
	/// Emitted when chat interlocutor ends file transfer.
	static let chatFileTransferEnd = "chatFileTransferEnd"
	
	/// Emitted after starting a download from server.
	static let downloadFileChunk = "downloadFileChunk"
	
	/// Emitted when file is completely downloaded.
	static let downloadFileEnd = "downloadFileEnd"
	
	static func get(event identifier: String, for room: String) -> String {
		return room + "." + identifier
	}
	
	private init() { }
}
