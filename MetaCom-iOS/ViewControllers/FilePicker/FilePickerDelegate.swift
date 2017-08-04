//
//  FilePickerDelegate.swift
//  MetaCom-iOS
//
//  Created by iKing on 12.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

protocol FilePickerDelegate: class {
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL)
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data, withUTI uti: String?)
	
	func filePickerWasCancelled(_ controller: FilePickerController)
	
	/// Called when file picker did pick `file` or `data` and was dismissed
	/// but should perform some processing before calling
	/// `filePicker(_:didPickFileAt:)` or filePicker(_:didPickData:uti:)
	func filePickerDidEndPicking(_ controller: FilePickerController)
	
	func filePickerHasFailed(_ controller: FilePickerController)
}

extension FilePickerDelegate {
	
	func filePickerWasCancelled(_ controller: FilePickerController) { }
	func filePickerDidEndPicking(_ controller: FilePickerController) { }
	func filePickerHasFailed(_ controller: FilePickerController) { }
}
