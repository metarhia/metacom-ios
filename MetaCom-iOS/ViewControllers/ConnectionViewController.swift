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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		hostTextField.delegate = self
		portTextField.delegate = self
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
		
		NotificationCenter.default.addObserver(self, selector: #selector(didConnect(_:)), name: Notification.Name.MCConnectionEstablished, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// TODO: Move out of this method
		connectButton.isActivityIndicatorVisible = false
		hostTextField.isEnabled = true
		portTextField.isEnabled = true
	}
	
	@IBAction func connect() {
		guard let host = hostTextField.text?.trim(), let port = Int(portTextField.text?.trim() ?? "") else {
			return
		}
		
		connectButton.isActivityIndicatorVisible = true
		hostTextField.isEnabled = false
		portTextField.isEnabled = false
		
		// TODO: Store conection
		_ = UserConnectionManager.instance.addConnection(host: host, port: port)
	}
	
	@objc private func didConnect(_ notification: Notification) {
		performSegue(withIdentifier: "submit", sender: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "submit" else {
			return
		}
		
		guard let host = hostTextField.text?.trim(), let port = portTextField.text?.trim() else {
			return
		}
		
		segue.destination.content.title = "\(host):\(port)"
	}
	
	@IBAction func unwindToConnection(_ segue: UIStoryboardSegue) {
		
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
