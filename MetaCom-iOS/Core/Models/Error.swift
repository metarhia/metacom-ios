//
//  Error.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 04.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

class MCError {
	
	let type: ErrorType
	fileprivate let code: Int
	
	init(of type: ErrorType) {
		
		self.type = type
		self.code = type.rawValue
	}
	
	init?(with code: Int) {
		
		guard let errorType = ErrorType(rawValue: code) else {
			return nil
		}
		
		self.type = errorType
		self.code = code
	}
	
	convenience init?(from error: Error) {
		
		let code = (error as NSError).code
		self.init(with: code)
	}
}

extension MCError {
	
	fileprivate static let descriptions = [
		30 : "Tried joining room with more then two people in it.",
		31 : "Tried to perform chat-related action while not in chat.",
		32 : "Chat room contains only the sender.",
		33 : "Tried to download file with incorrect code.",
		34 : "Occurs when user tries to finish uploading file to the server without starting it first.",
		35 : "Occurs when user tries to upload next file chunk to the server without first receiving callback for the previous chunk.",
		133 : "Connection lost due to unknown reasons.",
		134 : "Chat not found.",
		135 : "File wasn`t sent."
	]
	
	public enum ErrorType: Int {
		case roomTaken = 30
		case notInChat = 31
		case noInterlocutor = 32
		case noSuchfile = 33
		case uploadNotStarted = 34
		case previousUploadNotFinished = 35
		case connectionLost = 133
		case noChat = 134
		case fileFailed = 135
	}
}

extension MCError: LocalizedError {
	
	public var errorDescription: String? {
		return MCError.descriptions[code]
	}
}

extension MCError: CustomNSError {
	
	public static var errorDomain: String {
		return "com.metarhia.MetaCom"
	}
	
	public var errorCode: Int {
		return code
	}
}

extension MCError: CustomStringConvertible {
	
	public var description: String {
		return localizedDescription
	}
}
