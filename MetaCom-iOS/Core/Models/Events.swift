//
//  Events.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 20.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

enum Events: String {
	/// Emitted when another user joins current.
	case chatJoin = "chatJoin"
	
	/// Emitted when chat interlocutor leaves the chat.
	case chatLeave = "chatLeave"
	
	/// Emitted when chat interlocutor sends a message.
	case message = "message"
	
	/// Emitted when chat interlocutor starts file transfer
	case chatFileTransferStart = "chatFileTransferStart"
	
	/// Emitted when chat interlocutor sends file chunk.
	case chatFileTransferChunk = "chatFileTransferChunk"
	
	/// Emitted when chat interlocutor ends file transfer.
	case chatFileTransferEnd = "chatFileTransferEnd"
	
	/// Emitted when starting a download from server
	case downloadFileStart = "downloadFileStart"
	
	/// Emitted after starting a download from server.
	case downloadFileChunk = "downloadFileChunk"
	
	/// Emitted when file is completely downloaded.
	case downloadFileEnd = "downloadFileEnd"
	
	static func notification(ofEvent identifier: Events, for room: String = "") -> Notification.Name {
		return Notification.Name(name(ofEvent: identifier, for: room))
	}
	
	static func name(ofEvent identifier: Events.RawValue, for room: String = "") -> String {
		return room + "." + identifier
	}
	
	static func name(ofEvent identifier: Events, for room: String = "") -> String {
		return room + "." + identifier.rawValue
	}
}
