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
	@IBOutlet weak var infoLabel: UILabel!
	
	// MARK: - Upload
	
	@IBAction func upload() {
		
		let alert = UIAlertController.filePicker(with: self, rootController: self)
		present(alert, animated: true)
	}
	
	var isInterfaceLocked: Bool = false {
		didSet {
			uploadButton.isEnabled = !isInterfaceLocked
			downloadButton.isEnabled = !isInterfaceLocked
		}
	}
	
	// Temporary. For demonstration.
	fileprivate func showUploading() {
		isInterfaceLocked = true
		infoLabel.text = "Uploading..."
		infoLabel.isHidden = false
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
			guard let `self` = self else {
				return
			}
			
			self.isInterfaceLocked = false
			self.infoLabel.text = "Uploading..."
			self.infoLabel.isHidden = true
			
			let code = "31415926535"
			let alert = UIAlertController(title: "Upload",
			                              message: "Your file was uploaded. Code is \(code).",
				preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel))
			self.present(alert, animated: true)
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

}

// MARK: - Temporary solution

extension FilesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		picker.dismiss(animated: true, completion: nil)
		showUploading()
	}
	
}

extension FilesViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
		showUploading()
	}
}
