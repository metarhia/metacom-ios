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
			
			self?.isInterfaceLocked = false
			self?.infoStackView.isHidden = true
			
			let fileCode = "31415926535"
      self?.present(alert: UIAlerts.uploaded(withCode: fileCode), animated: true)
		}
	}
	
	// MARK: - Download
	@IBAction func download() {
    
    let downloadCompletion = { (file: (data: Data, extension: String)?, error: Error?) in

      // TODO: - Handle downloaded file or error here
    }
    
    let downloadAlert = UIAlerts.download { code in
      
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
    
    guard let fileCode = code else {
      return
    }
    
    present(alert: UIAlerts.uploaded(withCode: fileCode), animated: true)
  }
  
  func filePicker(_ controller: FilePickerController, didPickData data: Data, withUTI uti: String?) {
    
    manager?.upload(data, completion: uploadCompletion)
//    showUploading()
  }
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
    
    manager?.upload(from: url, completion: uploadCompletion)
//		showUploading()
	}
}
