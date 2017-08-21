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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		uploadButton.centerLayoutVertically()
		downloadButton.centerLayoutVertically()
	}
	
	// MARK: - Upload
	
	@IBAction func upload() {
		let filePicker = FilePickerController(delegate: self)
		if let popover = filePicker.alertController.popoverPresentationController {
			popover.sourceView = uploadButton
			popover.sourceRect = uploadButton.bounds
			popover.permittedArrowDirections = .down
		}
		present(filePicker, animated: false)
	}
	
	// MARK: - Download
	@IBAction func download() {
		
		var fileCode: String?
		
		let downloadCompletion = { [weak self] (file: (data: Data, extension: String)?, error: Error?) in
			guard let `self` = self else {
				return
			}
			
			self.isInterfaceLocked = false
			self.infoStackView.isHidden = true
			
			// `fileCode` never shouldn't be `nil`
			let code = fileCode ?? ""
			
			guard error == nil, let file = file else {
				self.present(alert: UIErrors.fileDownloadFailed(filePlaceholder: "File with code \"\(code)\""), animated: true)
				return
			}
			
			guard let path = UIKit.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
				self.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			let fileURL = path.appendingPathComponent(code).appendingPathExtension(file.extension)
			
			guard (try? file.data.write(to: fileURL)) != nil else {
				self.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			let share = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			share.completionWithItemsHandler = { _ in
				try? UIKit.FileManager.default.removeItem(at: fileURL)
			}
			
			if let popover = share.popoverPresentationController {
				popover.sourceView = self.downloadButton
				popover.sourceRect = self.downloadButton.bounds
				popover.permittedArrowDirections = .down
			}
			
			self.present(share, animated: true)
		}
		
		let dowloadHandler: (String) -> () = { [weak self] code in
			guard let `self` = self else {
				return
			}
			
			self.isInterfaceLocked = true
			self.infoLabel.text = "downloading_dots".localized
			self.infoStackView.isHidden = false
			
			fileCode = code
			
			let manager = UserConnectionManager.instance.currentConnection?.fileManager
			manager?.download(from: code, completion: downloadCompletion)
		}
		
		let downloadAlert = UIAlerts.download(handler: dowloadHandler, textFieldDelegate: self)
		
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
		infoLabel.text = "uploading_dots".localized
		infoStackView.isHidden = false
	}
	
	func filePickerHasFailed(_ controller: FilePickerController) {
		isInterfaceLocked = false
		infoStackView.isHidden = true
		
		present(alert: UIErrors.genericError, animated: true)
	}
}

// MARK: - UITextFieldDelegate

extension FilesViewController: UITextFieldDelegate {
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return string.isEmpty || !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}
