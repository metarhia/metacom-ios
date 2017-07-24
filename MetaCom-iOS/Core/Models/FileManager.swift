//
//  FileManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	A type representing a user connection file manager.
*/
final class FileManager {
	
	public let connection: Connection
	
	/**
		Create new `FileManager` instance.
		- parameters:
			- connection: transport connection.
	*/
	init(connection: Connection) {
		self.connection = connection
	}
	
	/**
		Upload specified data to server.
		- parameters:
			- data: data being uploaded.
			- completion: callback on completion.
	*/
	func upload(_ data: Data, _ completion: (String?, Error?) -> Void) {
		
	}
	
	/**
		Upload specified data to server.
		- parameters:
			- code: identifier of the downloaded file.
			- completion: callback on completion.
	*/
	func download(_ code: String, _ completion: (Data?, Error?) -> Void) {
		
	}
extension Constants {
	
	/// Chunk Size currently has to be < 4 mb.
	fileprivate static let chunkSize = 1024 * 1024
}
