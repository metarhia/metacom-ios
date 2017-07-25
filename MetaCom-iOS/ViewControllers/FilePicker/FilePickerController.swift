//
//  FilePickerController.swift
//  MetaCom-iOS
//
//  Created by iKing on 12.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import MobileCoreServices

// MARK: - UIImagePickerController convenience init

private extension UIImagePickerController {
	
	convenience init(sourceType type: UIImagePickerControllerSourceType, delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
		self.init()
		self.sourceType = type
		self.delegate = delegate
		if let types = UIImagePickerController.availableMediaTypes(for: type) {
			self.mediaTypes = types
		}
	}
}

// MARK: - FilePickerController

class FilePickerController: UIViewController {
	
	weak var delegate: FilePickerDelegate?
	
	// MARK: - Initialization
	
	convenience init(delegate: FilePickerDelegate) {
		self.init()
		self.delegate = delegate
	}
	
	override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		self.modalPresentationStyle = .overCurrentContext
	}
	
	// MARK: - View Controller Lifecycle
	
	private var alertAlreadyPresented = false
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !alertAlreadyPresented {
			present(alert: UIPicker.filePicker(self), animated: true)
			alertAlreadyPresented = true
		}
	}
	
	fileprivate func dismiss() {
		presentingViewController?.dismiss(animated: false)
	}
}

extension FilePickerController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
		delegate?.filePicker(self, didPickFileAt: url)
		
		self.dismiss()
	}
	
	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		self.dismiss()
	}
}

extension FilePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
		picker.dismiss(animated: true, completion: self.dismiss)
		
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
			
			guard let data = UIImagePNGRepresentation(image) else {
				return
			}
			
			delegate?.filePicker(self, didPickData: data, withUTI: String(kUTTypePNG))
		} else if let url = info[UIImagePickerControllerMediaURL] as? URL {
			delegate?.filePicker(self, didPickFileAt: url)
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: self.dismiss)
	}
}
