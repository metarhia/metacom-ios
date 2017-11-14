//
//  UIViewController+UIAlertRepresentable.swift
//  MetaCom-iOS
//
//  Created by iKing on 08.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

// TODO: - Fix naming in multiple places.

typealias ImagePickerDelegate = UIImagePickerControllerDelegate & UINavigationControllerDelegate
typealias PickerDelegate = ImagePickerDelegate & UIDocumentPickerDelegate

protocol UIAlertRepresentable {
	
	var alertController: UIAlertController { get }
}

private protocol UIAlertActionRepresentable {
	
	var alertAction: UIAlertAction { get }
}

private enum Actions: UIAlertActionRepresentable {
	
	case download(handler: ((UIAlertAction) -> Void)?)
	case copy(code: String)
	
	case confirm(withBlock: (() -> ())?)
	case cancel(withBlock: (() -> ())?)
	
	case generic(withTitle: String, style: UIAlertActionStyle, block: (() -> ())?)
	
	var alertAction: UIAlertAction {
		
		switch self {
		case .download(handler: let block):
			return UIAlertAction(title: "download".localized, style: .default, handler: block)
			
		case .copy(let code):
			return UIAlertAction(title: "copy".localized, style: .cancel) { _ in
				UIPasteboard.general.string = code
			}
			
		case .confirm(withBlock: let block):
			return UIAlertAction(title: "ok".localized, style: .default) { _ in
				block?()
			}
			
		case .cancel(withBlock: let block):
			return UIAlertAction(title: "cancel".localized, style: .cancel) { _ in
				block?()
			}
			
		case .generic(withTitle: let title, style: let style, block: let block):
			return UIAlertAction(title: title, style: style) { _ in
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
		
		var alertAction: UIAlertAction {
			
			switch self {
			case .photoLibrary(let controller):
				
				let block = { [unowned controller] (_: UIAlertAction) in
					
					let imagePicker = UIImagePickerController()
					imagePicker.sourceType = .photoLibrary
					imagePicker.delegate = controller
					
					if let types = UIImagePickerController.availableMediaTypes(for: imagePicker.sourceType) {
						imagePicker.mediaTypes = types
					}
					
					let authStatus = PHPhotoLibrary.authorizationStatus()
					if authStatus == .notDetermined {
						PHPhotoLibrary.requestAuthorization { _ in
							controller.present(imagePicker, animated: true)
						}
					} else {
						controller.present(imagePicker, animated: true)
					}
					
				}
				
				return UIAlertAction(title: "photo_library".localized, style: .default, handler: block)
				
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
				
				return UIAlertAction(title: "camera".localized, style: .default, handler: block)
			}
		}
	}
}

extension Actions {
	
	enum DocumentPicker<C: UIViewController>: UIAlertActionRepresentable where C: UIDocumentPickerDelegate {
		
		typealias Controller = C
		
		case iCloudDrive(controller: Controller)
		
		var alertAction: UIAlertAction {
			
			switch self {
			case .iCloudDrive(let controller):
				
				let block = { [unowned controller] (_: UIAlertAction) in
					
					let types = [String(kUTTypeItem)]
					let documentPickerController = UIDocumentPickerViewController(documentTypes: types, in: .import)
					documentPickerController.delegate = controller
					controller.present(documentPickerController, animated: true)
				}
				
				return UIAlertAction(title: "idrive".localized, style: .default, handler: block)
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
	
	var alertController: UIAlertController {
		
		switch self {
		case .filePicker(let picker):
			
			let photoPickerActions = Actions.PhotoPicker<PickerController>.self
			let documentPickerActions = Actions.DocumentPicker<PickerController>.self
			
			let photoLibrary = photoPickerActions.photoLibrary(controller: picker).alertAction
			let camera = photoPickerActions.camera(controller: picker).alertAction
			let drive = documentPickerActions.iCloudDrive(controller: picker).alertAction
			
			let dismiss = Actions.cancel {
				picker.presentingViewController?.dismiss(animated: false)
				}.alertAction
			
			photoLibrary.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
			camera.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
			
			return pickerController(with: photoLibrary, camera, drive, dismiss)
		}
	}
}

enum UIErrors: UIAlertRepresentable {
	
	case chatJoiningFailed
	case fileUploadFailed
	case fileDownloadFailed(filePlaceholder: String)
	case connectionFailed
	case genericError
	
	private func errorController(with message: String) -> UIAlertController {
		
		let error = UIAlertController(title: "error".localized, message: message, preferredStyle: .alert)
		error.addAction(Actions.confirm(withBlock: nil).alertAction)
		
		return error
	}
	
	var alertController: UIAlertController {
		
		switch self {
		case .chatJoiningFailed:
			return errorController(with: "err_room_taken".localized)
		case .fileUploadFailed:
			return errorController(with: "err_upload_failed".localized)
		case .fileDownloadFailed(let code):
			return errorController(with: String(format: "err_download_failed".localized, code))
		case .connectionFailed:
			return errorController(with: "err_connection_failed".localized)
		case .genericError:
			return errorController(with: "err_generic".localized)
		}
	}
}

enum UIAlerts: UIAlertRepresentable {
	
	case leavingChat(confirm: (() -> ())?, exportAndConfirm: (() -> ())?, deny: (() -> ())?)
	case leavingServer(confirm: (() -> ())?, deny: (() -> ())?)
	
	case uploaded(withCode: String)
	case download(handler: (String) -> (), textFieldDelegate: UITextFieldDelegate?)
	
	private func alertController(entitled: String, message: String? = nil, actions: UIAlertAction...) -> UIAlertController {
		
		let alert = UIAlertController(title: entitled, message: message, preferredStyle: .alert)
		actions.forEach(alert.addAction(_:))
		return alert
	}
	
	var alertController: UIAlertController {
		
		switch self {
		case .leavingChat(confirm: let confirmation, exportAndConfirm: let confirmationWithExport, deny: let denial):
			return alertController(
				entitled: "leave_chat".localized,
				message: "leave_chat_desc".localized,
				actions:
					Actions.generic(withTitle: "leave_chat_confirmation".localized, style: .default, block: confirmation).alertAction,
					Actions.generic(withTitle: "leave_chat_confirmation_with_export".localized, style: .default, block: confirmationWithExport).alertAction,
					Actions.cancel(withBlock: denial).alertAction
			)
			
		case .leavingServer(confirm: let confirmation, deny: let denial):
			return alertController(
				entitled: "leave_server".localized,
				message: "leave_server_desc".localized,
				actions: Actions.confirm(withBlock: confirmation).alertAction, Actions.cancel(withBlock: denial).alertAction
			)
			
		case .uploaded(withCode: let fileCode):
			return alertController(
				entitled: "upload".localized,
				message: String(format: "upload_desc".localized, fileCode),
				actions: Actions.copy(code: fileCode).alertAction, Actions.confirm(withBlock: nil).alertAction
			)
			
		case .download(let handler, let delegate):
			
			let alert = alertController(
				entitled: "download_desc".localized,
				actions: Actions.cancel(withBlock: nil).alertAction
			)
			
			let downloadHandler: ((UIAlertAction) -> Void)? = { [weak alert] _ in
				
				guard let code = alert?.textFields?.first?.text, !code.isEmpty else {
					return
				}
				
				handler(code)
			}
			
			let load = Actions.download(handler: downloadHandler).alertAction
			load.isEnabled = false
			
			let textFieldConfiguration: ((UITextField) -> Void)? = { textField in
				textField.placeholder = "file_code".localized
				textField.returnKeyType = .done
				textField.enablesReturnKeyAutomatically = true
				textField.clearButtonMode = .whileEditing
				textField.delegate = delegate
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
		present(alert.alertController, animated: flag, completion: completion)
	}
}
