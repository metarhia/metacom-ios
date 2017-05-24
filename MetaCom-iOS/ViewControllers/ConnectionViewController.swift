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
	@IBOutlet weak var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        hostTextField.delegate = self
		portTextField.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// TODO: Move out of this method
		submitButton.isActivityIndicatorVisible = false
		hostTextField.isEnabled = true
		portTextField.isEnabled = true
	}
	
	@IBAction func submit() {
		submitButton.isActivityIndicatorVisible = true
		hostTextField.isEnabled = false
		portTextField.isEnabled = false
		
		// TODO: Replace with attempting to connect to the specified host:port
		// TODO: Handle connection errors
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
			self.performSegue(withIdentifier: "submit", sender: nil)
		}
	}
	
	@IBAction func unwindToConnection(_ segue: UIStoryboardSegue) {
		
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "submit" else {
			return
		}
		
		guard let host = hostTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
		      let port = portTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
			return
		}
		
		(segue.destination as? UINavigationController)?.rootViewController?.title = "\(host):\(port)"
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
			submit()
		}
		return false
	}
}
