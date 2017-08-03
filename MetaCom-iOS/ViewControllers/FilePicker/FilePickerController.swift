//
//  FilePickerController.swift
//  MetaCom-iOS
//
//  Created by iKing on 12.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import Photos
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
	
	private(set) lazy var alertController: UIAlertController = UIPicker.filePicker(self).alertController
	
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
			present(alertController, animated: true)
			alertAlreadyPresented = true
		}
	}
	
	fileprivate func dismiss() {
		presentingViewController?.dismiss(animated: false)
	}
}

extension FilePickerController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
		self.dismiss()
		delegate?.filePickerDidEndPicking(self)
		delegate?.filePicker(self, didPickFileAt: url)
	}
	
	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		self.dismiss()
		delegate?.filePickerWasCancelled(self)
	}
}

extension FilePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
		picker.dismiss(animated: true, completion: self.dismiss)
		delegate?.filePickerDidEndPicking(self)
		
		if let mediaUrl = info[UIImagePickerControllerMediaURL] as? URL {
			delegate?.filePicker(self, didPickFileAt: mediaUrl)
		} else if let assetsLibraryURL = info[UIImagePickerControllerReferenceURL] as? URL {
			let assets = PHAsset.fetchAssets(withALAssetURLs: [assetsLibraryURL], options: nil)
			
			guard let asset = assets.firstObject else {
				delegate?.filePickerHasFailed(self)
				return
			}
			
			PHImageManager.default().requestImageData(for: asset, options: nil) { (data, uti, _, _) in
				guard let data = data, let uti = uti else {
					self.delegate?.filePickerHasFailed(self)
					return
				}
				self.delegate?.filePicker(self, didPickData: data, withUTI: uti)
			}
		} else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
			DispatchQueue.global().async {
				guard let data = UIImageJPEGRepresentation(image, 1) else {
					self.delegate?.filePickerHasFailed(self)
					return
				}
				
				DispatchQueue.main.async {
					self.delegate?.filePicker(self, didPickData: data, withUTI: String(kUTTypeJPEG))
				}
			}
		} else {
			self.delegate?.filePickerHasFailed(self)
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: self.dismiss)
		delegate?.filePickerWasCancelled(self)
	}
}
