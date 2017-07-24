//
//  FileManager.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation
import MobileCoreServices

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
extension FileManager {
  
  /**
    Construct a mime type from the uniform type identifier.
   	- parameters:
   		- uti: uniform type identifier.
   	- returns: mime type for the specfied uniform type identifier.
   */
  class func extractMimeType(from uti: String?) -> String {
    
    guard let type = uti, let mime = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassMIMEType) else {
      return extractMimeType(from: String(kUTTypeData))
    }
    
    return mime.takeRetainedValue() as String
  }
  
  /**
   	Construct a file mime type from the url.
    - parameters:
   		- url: url of the file.
   	- returns: mime type of the file specified by url.
   */
  class func extractMimeType(from url: URL) -> String {
    
    let pathExtension = url.pathExtension as NSString
    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil) else {
      return extractMimeType(from: String(kUTTypeData))
    }
    
    return extractMimeType(from: String(uti.takeRetainedValue()))
  }
  
  /**
   	Construct a file extension from the given mime type.
    - parameters:
    	- mimeType: mime type represented in string.
   	- returns: file extension for the specified mime type or an empty string.
   */
  class func extractExtension(from mimeType: String) -> String {
    
    let emptyString = "" as CFString
    
    let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
    let utiValue = uti?.takeRetainedValue() ?? emptyString
    let fileExtension = UTTypeCopyPreferredTagWithClass(utiValue, kUTTagClassFilenameExtension)
    
    return String(fileExtension?.takeRetainedValue() ?? emptyString)
  }
}

extension Constants {
	
	/// Chunk Size currently has to be < 4 mb.
	fileprivate static let chunkSize = 1024 * 1024
}
