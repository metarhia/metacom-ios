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

    override func viewDidLoad() {
        super.viewDidLoad()

        hostTextField.delegate = self
		portTextField.delegate = self
    }
	
	@IBAction func submit() {
		performSegue(withIdentifier: "submit", sender: nil)
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
			submit()
		}
		return false
	}
}
