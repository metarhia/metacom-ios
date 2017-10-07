//
//  Remote.swift
//  MetaCom-iOS-Device
//
//  Created by iKing on 05.10.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

struct Remote {
	
	let host: String
	let port: Int
	
	init(host: String, port: Int) {
		self.host = host
		self.port = port
	}
	
	init?(connectionString string: String) {
		let components = string.split(separator: ":")
		let host = components.dropLast().joined(separator: "")
		
		guard let last = components.last, let port = Int(last), !host.isEmpty else {
			return nil
		}
		
		self.init(host: host, port: port)
	}
	
	var connectionString: String {
		return host + ":\(port)"
	}
}

extension Remote: CustomStringConvertible {
	
	var description: String {
		return connectionString
	}
}

extension Remote: Equatable {
	
	static func ==(lhs: Remote, rhs: Remote) -> Bool {
		return lhs.host == rhs.host && lhs.port == rhs.port
	}
}
