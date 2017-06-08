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
	@IBOutlet weak var joinButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		chatNameTextField.delegate = self
		
		updateButtonState()
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
	}
	
	private var isInterfaceLocked: Bool = false {
		didSet {
			chatNameTextField.isEnabled = !isInterfaceLocked
			joinButton.isActivityIndicatorVisible = isInterfaceLocked
		}
	}
	
	@IBAction func joinChat() {
		guard let name = chatNameTextField.text?.trim(), !name.isEmpty else {
			present(UIAlertController.chatJoiningFailed(), animated: true)
			return
		}
		
		guard let chatManager = UserConnectionManager.instance.currentConnection?.chatManager else {
			present(UIAlertController.genericError(), animated: true)
			return
		}
		
		isInterfaceLocked = true
		
		chatManager.addRoom(named: name) { [weak self] error in
			guard let `self` = self else {
				return
			}
			
			defer {
				self.isInterfaceLocked = false
			}
			
			guard error == nil else {
				self.present(UIAlertController.chatJoiningFailed(), animated: true)
				return
			}
			
			self.performSegue(withIdentifier: "show.chat", sender: nil)
		}
	}
	
	@IBAction func nameChanged() {
		updateButtonState()
	}
	
	func updateButtonState() {
		joinButton.isEnabled = chatNameTextField.text?.isEmpty == false
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "show.chat" else {
			return
		}
		
		guard let chatController = segue.destination.content as? ChatViewController else {
			return
		}
		
		chatController.chat = UserConnectionManager.instance.currentConnection?.chatManager.currentChat
	}
	
	@IBAction func unwindToChatSetup(_ segue: UIStoryboardSegue) {
		guard let chatManager = UserConnectionManager.instance.currentConnection?.chatManager else {
			return
		}
		
		guard let chat = chatManager.currentChat else {
			return
		}
		
		chatManager.removeRoom(chat)
	}
	
}

// MARK: - UITextFieldDelegate

extension NewChatViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		joinChat()
		return false
	}
}
