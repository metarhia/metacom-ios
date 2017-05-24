//
//  FilesViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class FilesViewController: UIViewController {
	
	@IBAction func upload() {
		let alert = UIAlertController(title: "Upload",
		                              message: "Your file was uploaded. Code is 31415926535.",
		                              preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
	
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
			// TODO: Perform download
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
