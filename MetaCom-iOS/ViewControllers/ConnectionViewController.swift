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
	@IBOutlet weak var connectButton: ActivityButton!
	
	@IBOutlet weak var bottomSpace: NSLayoutConstraint!
	
	weak var remotesCompletionsView: CompletionsView?
	
	private var host: String? {
		guard let host = hostTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !host.isEmpty else {
			return nil
		}
		return host
	}
	
	private var port: Int? {
		guard let port = portTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !port.isEmpty else {
			return nil
		}
		return Int(port)
	}
	
	private var shouldConnectOnAppear = false
	
	// MARK: - View Controller Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		hostTextField.delegate = self
		portTextField.delegate = self
		
		let completionsView = CompletionsView()
		completionsView.delegate = self
		hostTextField.inputAccessoryView = completionsView
		remotesCompletionsView = completionsView
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
		
		if let remote = UserConnectionManager.instance.recentRemote {
			setRemote(remote)
			shouldConnectOnAppear = UserConnectionManager.instance.needReconnect
		}
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(remotesDidChange(_:)),
		                                       name: RemotesManager.remotesDidChangeNotification,
		                                       object: RemotesManager.shared)
		
		updateButtonState()
		updateRemotesCompletions()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		registerKeyboardNotifications()
		
		if shouldConnectOnAppear {
			shouldConnectOnAppear = false
			connect()
		}
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
	
	override var preferredStatusBarStyle : UIStatusBarStyle {
		return .lightContent
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - UI updating stuff
	
	private var isInterfaceLocked: Bool = false {
		didSet {
			hostTextField.isEnabled = !isInterfaceLocked
			portTextField.isEnabled = !isInterfaceLocked
			connectButton.isActivityIndicatorVisible = isInterfaceLocked
		}
	}
	
	fileprivate func setRemote(_ remote: Remote) {
		hostTextField.text = remote.host
		portTextField.text = "\(remote.port)"
		updateButtonState()
		updateRemotesCompletions()
	}
	
	private var shouldUnlockInterfaceOnDisappear: Bool = true
	
	private func setBottomSpace(_ space: CGFloat, animated: Bool = true) {
		bottomSpace.constant = space
		UIView.animate(withDuration: animated ? 0.3 : 0, animations: view.layoutIfNeeded)
	}
	
	private func updateButtonState() {
		connectButton.isEnabled = host != nil && port != nil
	}
	
	@IBAction func textFieldValueChanged(_ textField: UITextField) {
		if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
			textField.text = ""
		}
		updateButtonState()
		updateRemotesCompletions()
	}
	
	@objc private func remotesDidChange(_ notification: Notification) {
		updateRemotesCompletions()
	}
	
	private func updateRemotesCompletions() {
		let remotes = RemotesManager.shared.remotes(havingPrefix: host ?? "")
		remotesCompletionsView?.completions = Array(remotes[0 ..< min(10, remotes.count)])
	}
	
	// MARK: - Connection
	
	@IBAction func connect() {
		guard let host = host, let port = port else {
			present(alert: UIErrors.connectionFailed, animated: true)
			return
		}
		
		isInterfaceLocked = true
		
		UserConnectionManager.instance.addConnection(host: host, port: port) { [weak self] connection in
			guard let `self` = self else {
				return
			}
			
			guard let userConnection = connection else {
				self.present(alert: UIErrors.connectionFailed, animated: true)
				self.isInterfaceLocked = false
				return
			}
			
			UserConnectionManager.instance.currentConnection = userConnection
			self.performSegue(withIdentifier: "submit", sender: nil)
		}
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "submit" else {
			return
		}
		
		guard let host = host, let port = port else {
			return
		}
		
		let navigationController = segue.destination as? UINavigationController
		let destinationController = navigationController?.viewControllers.first ?? segue.destination
		
		destinationController.title = "\(host):\(port)"
	}
	
	@IBAction func unwindToConnection(_ segue: UIStoryboardSegue) {
		
		guard let current = UserConnectionManager.instance.currentConnection else {
			return
		}
		
		UserConnectionManager.instance.removeConnection(current)
	}
	
	@IBAction func showServerIstallationGuide() {
		if let url = URL(string: "link_server_installation_guide".localized) {
			UIApplication.shared.open(url)
		}
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
			setBottomSpace(kbRect.height + 10)
		}
	}
	
	@objc private func keyboardWillHide(_ notification: Notification) {
		setBottomSpace(20)
	}
	
	@objc private func keyboardWillChangeFrame(_ notification: Notification) {
		if let kbRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			setBottomSpace(kbRect.height + 10)
		}
	}
	
}

// MARK: - UITextFieldDelegate

extension ConnectionViewController: UITextFieldDelegate {
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return !((textField.text?.isEmpty != false) && string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
	}
	
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
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		// Fixes UITextField's strange behavior when text "jumps"
		// to the left edge of control and back to normal position
		// when user selects another UITextField
		textField.layoutIfNeeded()
	}
}

// MARK: - CompletionsViewDelegate

extension ConnectionViewController: CompletionsViewDelegate {
	
	func completionsView(_ completionsView: CompletionsView, didPickItemAt index: Int) {
		guard let remote = completionsView.completions[index] as? Remote else {
			return
		}
		
		setRemote(remote)
	}
}
