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
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
	}
	
	@IBAction func startChat() {
		performSegue(withIdentifier: "show.chat", sender: nil)
	}
	
	@IBAction func unwindToChatSetup(_ segue: UIStoryboardSegue) {
		
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "show.chat" else {
			return
		}
		
		segue.destination.content.title = chatNameTextField.text?.trim()
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
