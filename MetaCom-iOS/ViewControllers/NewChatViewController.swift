//
//  NewChatViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class NewChatViewController: UIViewController {
	
	@IBOutlet weak var chatNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        chatNameTextField.delegate = self
    }

	@IBAction func startChat() {
		performSegue(withIdentifier: "show.chat", sender: nil)
	}
	
	@IBAction func unwindToChatSetup(_ segue: UIStoryboardSegue) {
		
	}

}

// MARK: - UITextFieldDelegate

extension NewChatViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		startChat()
		return false
	}
}
