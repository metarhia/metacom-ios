//
//  UIAlertController+Templates.swift
//  MetaCom-iOS
//
//  Created by iKing on 08.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIAlertController {
	
	// MARK: - Info
	
	static func upload(code: String) -> UIAlertController {
		let alert = UIAlertController(title: "Upload",
		                              message: "Your file was uploaded. Code is \(code).",
		                              preferredStyle: .alert)
		
		let copy = UIAlertAction(title: "Copy", style: .cancel) { _ in
			UIPasteboard.general.string = code
		}
		
		alert.addAction(copy)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		
		return alert
	}
	
	static func leaveChat(confirm: (() -> ())? = nil, deny: (() -> ())? = nil) -> UIAlertController {
		let alert = UIAlertController(title: "Leave Chat",
		                              message: "Leaving the chat will cause losing conversation history.",
		                              preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			deny?()
		}))
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
			confirm?()
		}))
		
		return alert
	}
	
	// MARK: - Errors
	
	static func chatJoiningFailed() -> UIAlertController {
		let alert = UIAlertController(title: "Error", message: "An error occured while joining chat room. Try again.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		return alert
	}
	
	static func connectionFailed() -> UIAlertController {
		let alert = UIAlertController(title: "Error", message: "Impossible to connect to server. Please check specified host and port and try again.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		return alert
	}
	
	static func messageSendingFailed() -> UIAlertController {
		let alert = UIAlertController(title: "Error", message: "An error occured while sending message. Try again.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		return alert
	}
	
	static func genericError() -> UIAlertController {
		let alert = UIAlertController(title: "Error", message: "Something gone wrong...", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		return alert
	}
	
}
