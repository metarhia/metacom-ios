//
//  UIAlertController+Templates.swift
//  MetaCom-iOS
//
//  Created by iKing on 08.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import MobileCoreServices

// TODO: - Fix naming in multiple places.

typealias ImagePickerDelegate = UIImagePickerControllerDelegate & UINavigationControllerDelegate
typealias PickerDelegate = ImagePickerDelegate & UIDocumentPickerDelegate

protocol UIAlertRepresentable {
	
	var value: UIAlertController { get }
}

private protocol UIAlertActionRepresentable {
	
	var value: UIAlertAction { get }
}

private enum Actions: UIAlertActionRepresentable {
	
	case download(handler: ((UIAlertAction) -> Void)?)
	case copy(code: String)
	
	case confirm(withBlock: (() -> ())?)
	case cancel(withBlock: (() -> ())?)
	
	var value: UIAlertAction {
		
		switch self {
		case .download(handler: let block):
			return UIAlertAction(title: "Download", style: .default, handler: block)
			
		case .copy(let code):
			return UIAlertAction(title: "Copy", style: .cancel) { _ in
				UIPasteboard.general.string = code
			}
			
		case .confirm(withBlock: let block):
			return UIAlertAction(title: "OK", style: .default) { _ in
				block?()
			}
			
		case .cancel(withBlock: let block):
			return UIAlertAction(title: "Cancel", style: .cancel) { _ in
				block?()
			}
		}
	}
}

extension Actions {
	
	enum PhotoPicker<C: UIViewController>: UIAlertActionRepresentable where C: ImagePickerDelegate {
		
		/// `UIViewController` used in performing image picking actions.
		typealias Controller = C
		
		case photoLibrary(controller: Controller)
		case camera(controller: Controller)
		
		var value: UIAlertAction {
			
			switch self {
			case .photoLibrary(let controller):
				
				let block = { [unowned controller] (_: UIAlertAction) in
					
					let imagePicker = UIImagePickerController()
					imagePicker.sourceType = .photoLibrary
					imagePicker.delegate = controller
					
					if let types = UIImagePickerController.availableMediaTypes(for: imagePicker.sourceType) {
						imagePicker.mediaTypes = types
					}
					
					controller.present(imagePicker, animated: true)
				}
				
				return UIAlertAction(title: "Photo Library", style: .default, handler: block)
				
			case .camera(let controller):
				
				let block = { [unowned controller] (_: UIAlertAction) in
					
					let imagePicker = UIImagePickerController()
					imagePicker.sourceType = .camera
					imagePicker.delegate = controller
					
					if let types = UIImagePickerController.availableMediaTypes(for: imagePicker.sourceType) {
						imagePicker.mediaTypes = types
					}
					
					controller.present(imagePicker, animated: true)
				}
				
				return UIAlertAction(title: "Camera", style: .default, handler: block)
			}
		}
	}
}

extension Actions {
	
	enum DocumentPicker<C: UIViewController>: UIAlertActionRepresentable where C: UIDocumentPickerDelegate {
		
		typealias Controller = C
		
		case iCloudDrive(controller: Controller)
		
		var value: UIAlertAction {
			
			switch self {
			case .iCloudDrive(let controller):
				
				let block = { [unowned controller] (_: UIAlertAction) in
					
					let types = [String(kUTTypeItem)]
					let documentPickerController = UIDocumentPickerViewController(documentTypes: types, in: .import)
					documentPickerController.delegate = controller
					controller.present(documentPickerController, animated: true)
				}
				
				return UIAlertAction(title: "iCloud Drive", style: .default, handler: block)
			}
		}
	}
}

enum UIPicker<PickerController: UIViewController>: UIAlertRepresentable where PickerController: PickerDelegate {
	
	case filePicker(PickerController)
	
	private func pickerController(with actions: UIAlertAction...) -> UIAlertController {
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actions.forEach(alert.addAction(_:))
		return alert
	}
	
	var value: UIAlertController {
		
		switch self {
		case .filePicker(let picker):
			
			let photoPickerActions = Actions.PhotoPicker<PickerController>.self
			let documentPickerActions = Actions.DocumentPicker<PickerController>.self
			
			let photoLibrary = photoPickerActions.photoLibrary(controller: picker).value
			let camera = photoPickerActions.camera(controller: picker).value
			let drive = documentPickerActions.iCloudDrive(controller: picker).value
			
			let dismiss = Actions.cancel {
				picker.presentingViewController?.dismiss(animated: false)
				}.value
			
			photoLibrary.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
			camera.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
			
			return pickerController(with: photoLibrary, camera, drive, dismiss)
		}
	}
}

enum UIErrors: UIAlertRepresentable {
	
	case chatJoiningFailed
	case chatOnlyInterlocutor
	case fileUploadFailed
	case fileDownloadFailed(fileCode: String)
	case connectionFailed
	case messageSendingFailed
	case genericError
	
	private func errorController(with message: String) -> UIAlertController {
		
		let error = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		error.addAction(Actions.confirm(withBlock: nil).value)
		
		return error
	}
	
	var value: UIAlertController {
		
		switch self {
		case .chatJoiningFailed:
			return errorController(with: "An error occured while joining chat room. Try again.")
		case .chatOnlyInterlocutor:
			return errorController(with: "You are the only chat interlocutor")
		case .fileUploadFailed:
			return errorController(with: "Upload failed")
		case .fileDownloadFailed(let code):
			return errorController(with: "Downloading file with code \"\(code)\" failed. Check the code and try again.")
		case .connectionFailed:
			return errorController(with: "Impossible to connect to server. Please check specified host and port and try again.")
		case .messageSendingFailed:
			return errorController(with: "An error occured while sending message. Try again.")
		case .genericError:
			return errorController(with: "Something gone wrong...")
		}
	}
}

enum UIAlerts: UIAlertRepresentable {
	
	case leavingChat(confirm: (() -> ())?, deny: (() -> ())?)
	
	case uploaded(withCode: String)
	case download(handler: (String) -> ())
	
	private func alertController(entitled: String, message: String? = nil, actions: UIAlertAction...) -> UIAlertController {
		
		let alert = UIAlertController(title: entitled, message: message, preferredStyle: .alert)
		actions.forEach(alert.addAction(_:))
		return alert
	}
	
	var value: UIAlertController {
		
		switch self {
		case .leavingChat(confirm: let confirmation, deny: let denial):
			return alertController(
				entitled: "Leave Chat",
				message: "Leaving the chat will cause losing conversation history.",
				actions: Actions.confirm(withBlock: confirmation).value, Actions.cancel(withBlock: denial).value
			)
			
		case .uploaded(withCode: let fileCode):
			return alertController(
				entitled: "Upload",
				message: "Your file was uploaded. Code is \(fileCode).",
				actions: Actions.copy(code: fileCode).value, Actions.confirm(withBlock: nil).value
			)
			
		case .download(handler: let handler):
			
			let alert = alertController(
				entitled: "Enter download code:",
				actions: Actions.cancel(withBlock: nil).value
			)
			
			let downloadHandler: ((UIAlertAction) -> Void)? = { [weak alert] _ in
				
				guard let code = alert?.textFields?.first?.text, !code.isEmpty else {
					return
				}
				
				handler(code)
			}
			
			let load = Actions.download(handler: downloadHandler).value
			load.isEnabled = false
			
			let textFieldConfiguration: ((UITextField) -> Void)? = { textField in
				textField.returnKeyType = .done
				textField.enablesReturnKeyAutomatically = true
				textField.addAction(for: .editingChanged) { [weak textField, weak load] in
					load?.isEnabled = textField?.text?.isEmpty == false
				}
			}
			
			alert.addTextField(configurationHandler: textFieldConfiguration)
			alert.addAction(load)
			
			return alert
		}
	}
}

extension UIViewController {
	
	func present(alert: UIAlertRepresentable, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
		present(alert.value, animated: flag, completion: completion)
	}
}
