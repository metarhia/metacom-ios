//
//  FilesViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class FilesViewController: UIViewController {
	
	@IBOutlet weak var uploadButton: UIButton!
	@IBOutlet weak var downloadButton: UIButton!
	
	@IBOutlet weak var infoStackView: UIStackView!
	@IBOutlet weak var infoLabel: UILabel!
	@IBOutlet weak var cancelButton: UIButton!
	
	var isInterfaceLocked: Bool = false {
		didSet {
			uploadButton.isEnabled = !isInterfaceLocked
			downloadButton.isEnabled = !isInterfaceLocked
		}
	}
	
	// MARK: - Upload
	
	@IBAction func upload() {
		let filePicker = FilePickerController(delegate: self)
		present(filePicker, animated: false)
	}
	
	// MARK: - Download
	@IBAction func download() {
		
		var fileCode: String?
		
		let downloadCompletion = { [weak self] (file: (data: Data, extension: String)?, error: Error?) in
			
			// `fileCode` never shouldn't be `nil`
			let code = fileCode ?? ""
			
			guard error == nil, let file = file else {
				self?.present(alert: UIErrors.fileDownloadFailed(fileCode: code), animated: true)
				return
			}
			
			guard let path = UIKit.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
				self?.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			let fileURL = path.appendingPathComponent(code).appendingPathExtension(file.extension)
			
			guard (try? file.data.write(to: fileURL)) != nil else {
				self?.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			let share = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			share.completionWithItemsHandler = { _ in
				try? UIKit.FileManager.default.removeItem(at: fileURL)
			}
			
			self?.present(share, animated: true)
		}
		
		let downloadAlert = UIAlerts.download { code in
			
			fileCode = code
			
			let manager = UserConnectionManager.instance.currentConnection?.fileManager
			manager?.download(from: code, completion: downloadCompletion)
		}
		
		present(alert: downloadAlert, animated: true)
	}
	
	// MARK: -
	
	@IBAction func cancel() {
		
	}
}

// MARK: - FilePickerDelegate

extension FilesViewController: FilePickerDelegate {
	
	private var manager: FileManager? {
		return UserConnectionManager.instance.currentConnection?.fileManager
	}
	
	private func uploadCompletion(code: String?, error: Error?) {
		
		isInterfaceLocked = false
		infoStackView.isHidden = true
		
		guard let fileCode = code else {
			present(alert: UIErrors.fileUploadFailed, animated: true)
			return
		}
		
		present(alert: UIAlerts.uploaded(withCode: fileCode), animated: true)
	}
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data, withUTI uti: String?) {
		manager?.upload(data, completion: uploadCompletion)
	}
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
		manager?.upload(from: url, completion: uploadCompletion)
	}
	
	func filePickerDidEndPicking(_ controller: FilePickerController) {
		isInterfaceLocked = true
		infoLabel.text = "Uploading..."
		infoStackView.isHidden = false
	}
	
	func filePickerHasFailed(_ controller: FilePickerController) {
		isInterfaceLocked = false
		infoStackView.isHidden = true
		
		present(alert: UIErrors.genericError, animated: true)
	}
}
