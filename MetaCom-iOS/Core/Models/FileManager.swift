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
	func upload(_ data: Data, completion block: @escaping (String?, Error?) -> Void) {
		
		FileManager.upload(data: data, via: connection, method: "uploadFileChunk") { [unowned self] error in
			
			guard error == nil else {
				return block(nil, error)
			}
			
			self.connection.call(Constants.interfaceName, "endFileUpload") { block($0?.first as? String, $1) }
		}
	}
	
	/**
		Upload data from the specified url to server.
		- parameters:
			- url: data url.
			- completion: callback on completion.
	*/
	func upload(from url: URL, completion block: @escaping (String?, Error?) -> Void) {
		
		guard let data = try? Data(contentsOf: url) else {
			return block(nil, MCError(of: .fileFailed))
		}
		
		upload(data, completion: block)
	}
	
	/**
		Download data specified by the code from server.
		- parameters:
			- code: code specifying the file to download
			- block: block called upon failure or successful completion of the download.
	*/
	func download(from code: String, completion block: @escaping ((data: Data, extension: String)?, Error?) -> Void) {
		
		let downloadNotification = Events.notification(ofEvent: .downloadFileStart)
		let chunkNotification = Events.notification(ofEvent: .downloadFileChunk)
		let fileNotification = Events.notification(ofEvent: .downloadFileEnd)
		
		var tokens = [NSObjectProtocol]()
		let center = NotificationCenter.default
		let token = center.addObserver(forName: downloadNotification, object: connection, queue: nil) { [unowned self] notification in
			
			let event = notification.userInfo?[Constants.notificationObject] as? Event
			let argument = event?.arguments.first as? String
			let mimeType = argument ?? FileManager.extractMimeType(from: nil)
			let fileExtension = FileManager.extractExtension(from: mimeType)
			
			let notifications = (onChunkDownload: chunkNotification, onDownloadEnd: fileNotification)
			let onDownloadFinished: (Data?, Error?) -> () = { data, error in
				
				guard let fileData = data else {
					return block(nil, error)
				}
				
				block((data: fileData, extension: fileExtension), nil)
			}
			
			FileManager.download(listenTo: notifications, on: self.connection, completion: onDownloadFinished)
			tokens.forEach { center.removeObserver($0) }
		}
		
		tokens.append(token)
		
		connection.call(Constants.interfaceName, "downloadFile", [code]) { _, serverError in
			
			guard let error = serverError else {
				return
			}
			
			block(nil, MCError(from: error) ?? MCError(of: .noSuchfile))
			tokens.forEach { center.removeObserver($0) }
		}
	}
}

extension FileManager {
	
	/// Alias for the tuple representing notification names for the chunk download and download end events.
	typealias DownloadEvents = (onChunkDownload: Notification.Name, onDownloadEnd: Notification.Name)
	
	/**
		Download data from server via specified connection.
		- parameters:
			- events: events to subscribe in order to receive chunks and download end events.
			- connection: connection used to receive data.
			- block: block called upon failure or successful completion of the download.
	*/
	class func download(listenTo events: DownloadEvents, on connection: Connection, completion block: @escaping (Data?, Error?) -> ()) {
		
		var buffer: Data? = Data()
		var tokens = [NSObjectProtocol]()
		let center = NotificationCenter.default
		
		let onChunkBlock: (Notification) -> Void = { notification in
			
			guard let event = notification.userInfo?[Constants.notificationObject] as? Event,
				let chunk = event.arguments.first as? String else {
					buffer = nil
					return block(buffer, MCError(of: .fileFailed))
			}
			
			let dataChunk = Data(base64Encoded: chunk) ?? Data()
			buffer?.append(dataChunk)
		}
		
		let onFileBlock: (Notification) -> Void = { notification in
			tokens.forEach({ NotificationCenter.default.removeObserver($0) })
			block(buffer, nil)
		}
		
		let t1 = center.addObserver(forName: events.onChunkDownload, object: connection, queue: nil, using: onChunkBlock)
		let t2 = center.addObserver(forName: events.onDownloadEnd, object: connection, queue: nil, using: onFileBlock)
		
		tokens = [t1, t2]
	}
	
	/**
		Upload data to server via specified connection and chunk sending method.
		- parameters:
			- data: raw data that will be sent to the server.
			- connection: connection used to send data.
			- method: chunk sending method
			- block: block called upon failure or successful completion of the upload.
	*/
	class func upload(data: Data, via connection: Connection, method: String, completion block: @escaping (Error?) -> ()) {
		
		let length = data.count
		var offset = 0
		var chunk = String()
		var error: MCError? = nil
		
		let semaphore = DispatchSemaphore(value: 1)
		let queueId = data.prefix(1).base.base64EncodedString()
		let queue = DispatchQueue(label: queueId, qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem)
		
		var onChunkSent: Callback?
		onChunkSent = { _, serverError in
			
			defer {
				semaphore.signal()
			}
			
			guard let unwrappedError = serverError else {
				return
			}
			
			let localError = MCError(with: (unwrappedError as NSError).code) ?? MCError(of: .fileFailed)
			
			guard localError.type == .previousUploadNotFinished else {
				error = localError
				return
			}
			
			Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
				connection.call(Constants.interfaceName, method, [chunk], onChunkSent)
				timer.invalidate()
			}
		}
		
		queue.async {
			
			repeat {
				
				semaphore.wait()
				
				let diff = length - offset
				let size = diff > Constants.chunkSize ? Constants.chunkSize : diff
				chunk = data.subdata(in: offset..<offset + size).base64EncodedString()
				
				guard error == nil else {
					semaphore.signal()
					break
				}
				
				connection.call(Constants.interfaceName, method, [chunk], onChunkSent)
				
				offset += size
			} while offset < length
			
			semaphore.wait()
			DispatchQueue.main.async {
				block(error)
			}
			semaphore.signal()
		}
	}
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
