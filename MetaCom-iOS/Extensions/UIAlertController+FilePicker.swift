//
//  UIAlertController+FilePicker.swift
//  MetaCom-iOS
//
//  Created by iKing on 09.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

// Important note **********************************************************************************
//
// Current solution is a kind of placeholder.
// When the mechanism of files selection and transmitting will be approved,
// this solution will be probably replaced with a custom `FilePickerController` class 
// and an indepenpent `FilePickerControllerDelegate` protocol or somethig like this.
//
// End of the note *********************************************************************************

typealias FilePickerDelegate = UIDocumentPickerDelegate & UIImagePickerControllerDelegate & UINavigationControllerDelegate

private extension UIImagePickerController {
	
	convenience init(sourceType type: UIImagePickerControllerSourceType, delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
		self.init()
		self.sourceType = type
		self.delegate = delegate
	}
}

extension UIAlertController {
	
	static func filePicker(with delegate: FilePickerDelegate, rootController root: UIViewController) -> UIAlertController {
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		let media = UIAlertAction(title: "Photo or Video", style: .default) { _ in
			
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			
			let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { _ in
				let imagePicker = UIImagePickerController(sourceType: .photoLibrary, delegate: delegate)
				root.present(imagePicker, animated: true)
			}
			
			let camera = UIAlertAction(title: "Camera", style: .default) { _ in
				let imagePicker = UIImagePickerController(sourceType: .camera, delegate: delegate)
				root.present(imagePicker, animated: true)
			}
			
			alert.addAction(photoLibrary)
			alert.addAction(camera)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			
			root.present(alert, animated: true)
		}
		
		let iCloudDrive = UIAlertAction(title: "iCloud Drive", style: .default) { _ in
			let documentPickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
			documentPickerController.delegate = delegate
			root.present(documentPickerController, animated: true)
		}
		
		alert.addAction(media)
		alert.addAction(iCloudDrive)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		return alert
	}
}
