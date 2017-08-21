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
	@IBOutlet weak var joinButton: ActivityButton!
	
	@IBOutlet weak var bottomSpace: NSLayoutConstraint!
	
	private var name: String? {
		guard let name = chatNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
			return nil
		}
		return name
	}
	
	
	// MARK: - View Controller Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		chatNameTextField.delegate = self
		
		updateButtonState()
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		registerKeyboardNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		unregisterKeyboardNotifications()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if shouldUnlockInterfaceOnDisappear && isInterfaceLocked {
			isInterfaceLocked = false
		}
	}
	
	// MARK: - UI updating stuff
	
	private var isInterfaceLocked: Bool = false {
		didSet {
			chatNameTextField.isEnabled = !isInterfaceLocked
			joinButton.isActivityIndicatorVisible = isInterfaceLocked
		}
	}
	
	private var shouldUnlockInterfaceOnDisappear: Bool = true
	
	private func setBottomSpace(_ space: CGFloat, animated: Bool = true) {
		bottomSpace.constant = space
		UIView.animate(withDuration: animated ? 0.3 : 0, animations: view.layoutIfNeeded)
	}
	
	private func updateButtonState() {
		joinButton.isEnabled = name != nil
	}
	
	@IBAction func nameChanged() {
		if chatNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
			chatNameTextField.text = ""
		}
		updateButtonState()
	}
	
	// MARK: - Joining Chat
	
	@IBAction func joinChat() {
		guard let name = name, let chatManager = UserConnectionManager.instance.currentConnection?.chatManager else {
			present(alert: UIErrors.genericError, animated: true, completion: nil)
			return
		}
		
		isInterfaceLocked = true
		
		chatManager.addRoom(named: name) { [weak self] error in
			guard let `self` = self else {
				return
			}
			
			guard error == nil else {
				self.present(alert: UIErrors.chatJoiningFailed, animated: true)
				self.isInterfaceLocked = false
				return
			}
			
			self.performSegue(withIdentifier: "show.chat", sender: nil)
		}
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "show.chat" else {
			return
		}
		
		let navigationController = segue.destination as? UINavigationController
		let rootController = navigationController?.viewControllers.first ?? segue.destination
		
		guard let chatController = rootController as? ChatViewController else {
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
	
	// MARK: - Handling keyboard events
	// Preventing controls overlapping by keyboard.
	// Perhaps will be replaced with another solution later.
	
	private func registerKeyboardNotifications() {
		let center = NotificationCenter.default
		center.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: .UIKeyboardDidShow, object: nil)
		center.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
		center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
	}
	
	private func unregisterKeyboardNotifications() {
		let center = NotificationCenter.default
		center.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
		center.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
		center.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
	}
	
	@objc private func keyboardDidShow(_ notification: Notification) {
		if let kbRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			setBottomSpace(kbRect.height - 40)
		}
	}
	
	@objc private func keyboardWillHide(_ notification: Notification) {
		setBottomSpace(0)
	}
	
	@objc private func keyboardWillChangeFrame(_ notification: Notification) {
		if let kbRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			setBottomSpace(kbRect.height - 40)
		}
	}
	
}

// MARK: - UITextFieldDelegate

extension NewChatViewController: UITextFieldDelegate {
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return !((textField.text?.isEmpty != false) && string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		joinChat()
		return false
	}
}
