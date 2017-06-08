//
//  ConnectionViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {
	
	@IBOutlet weak var hostTextField: UITextField!
	@IBOutlet weak var portTextField: UITextField!
	@IBOutlet weak var connectButton: UIButton!
	
	private var host: String? {
		guard let host = hostTextField.text?.trim(), !host.isEmpty else {
			return nil
		}
		return host
	}
	
	private var port: Int? {
		guard let port = portTextField.text?.trim(), !port.isEmpty else {
			return nil
		}
		return Int(port)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		hostTextField.delegate = self
		portTextField.delegate = self
		
		updateButtonState()
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
	}
	
	private var isInterfaceLocked: Bool = false {
		didSet {
			hostTextField.isEnabled = !isInterfaceLocked
			portTextField.isEnabled = !isInterfaceLocked
			connectButton.isActivityIndicatorVisible = isInterfaceLocked
		}
	}
	
	@IBAction func connect() {
		guard let host = host, let port = port else {
			// TODO: Show alert
			return
		}
		
		connectButton.isActivityIndicatorVisible = true
		hostTextField.isEnabled = false
		portTextField.isEnabled = false
		
		isInterfaceLocked = true
		
		UserConnectionManager.instance.addConnection(host: host, port: port) { [weak self] connection in
			guard let `self` = self else {
				return
			}
			
			defer {
				self.isInterfaceLocked = false
			}
			
			guard let userConnection = connection else {
				return
			}
			
			UserConnectionManager.instance.currentConnection = userConnection
			self.performSegue(withIdentifier: "submit", sender: nil)
		}
	}
	
	@IBAction func textFiledValueChanged() {
		updateButtonState()
	}
	
	func updateButtonState() {
		connectButton.isEnabled = host != nil && port != nil
	}

	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "submit" else {
			return
		}
		
		guard let host = host, let port = port else {
			return
		}
		
		segue.destination.content.title = "\(host):\(port)"
	}
	
	@IBAction func unwindToConnection(_ segue: UIStoryboardSegue) {
		guard let current = UserConnectionManager.instance.currentConnection else {
			return
		}
		
		UserConnectionManager.instance.removeConnection(current)
	}
	
}

// MARK: - UITextFieldDelegate

extension ConnectionViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let nextTag = textField.tag + 1;
		if let nextResponder = textField.superview?.viewWithTag(nextTag) {
			nextResponder.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
			connect()
		}
		return false
	}
}
