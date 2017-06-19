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
	
	// Temporary. For demonstration.
	fileprivate func showUploading() {
		isInterfaceLocked = true
		infoLabel.text = "Uploading..."
		infoStackView.isHidden = false
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
			guard let `self` = self else {
				return
			}
			
			self.isInterfaceLocked = false
			self.infoStackView.isHidden = true
			
			let code = "31415926535"
			self.present(UIAlertController.upload(code: code), animated: true)
		}
	}
	
	// MARK: - Download
	
	private weak var downloadAction: UIAlertAction?
	
	@IBAction func download() {
		let alert = UIAlertController(title: "Enter download code:",
		                              message: nil,
		                              preferredStyle: .alert)
		alert.addTextField { textField in
			textField.returnKeyType = .done
			textField.enablesReturnKeyAutomatically = true
			textField.addTarget(self, action: #selector(self.codeTextChanged(_:)), for: .editingChanged)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .cancel)
		let download = UIAlertAction(title: "Download", style: .default) { [weak alert] action in
			guard let code = alert?.textFields?.first?.text, !code.isEmpty else {
				print("No any code typed.")
				return
			}
			print("Downloading file with code: \(code).")
			// TODO: Try to perform download with specified `code`
			// TODO: Handle download errors
			// TODO: Visualize downloading process (show some status bar, perhaps)
		}
		download.isEnabled = false
		downloadAction = download
		alert.addAction(cancel)
		alert.addAction(download)
		present(alert, animated: true)
	}
	
	@objc private func codeTextChanged(_ textField: UITextField) {
		downloadAction?.isEnabled = textField.text?.isEmpty == false
	}
	
	// MARK: -
	
	@IBAction func cancel() {
		
	} 
	
}

// MARK: - FilePickerDelegate

extension FilesViewController: FilePickerDelegate {
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data) {
		showUploading()
	}
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
		showUploading()
	}
}
