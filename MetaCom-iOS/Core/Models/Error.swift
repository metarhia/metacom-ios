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
}

extension MCError {
	
	fileprivate static let descriptions = [133 : "Connection lost due to unknown reasons."]
	
	public enum ErrorType: Int {
		case connectionLost = 133
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
