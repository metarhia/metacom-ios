//
//  ChatViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import MobileCoreServices
import JSQMessagesViewController

// MARK: - Constants related to chat displaying

private struct ChatConstants {
	static let incomingSenderId = "incomingId"
	static let outgoingSenderId = "outgoingId"
	static let systemSenderId = "systemId"
}

// MARK: - ChatMessage

private class ChatMessage: JSQMessage {
	
	var message: Message?
	
	convenience init(message: Message) {
		let id = message.isIncoming ? ChatConstants.incomingSenderId : ChatConstants.outgoingSenderId
		switch message.content {
		case .text(let text):
			self.init(senderId: id, senderDisplayName: "", date: Date(), text: text)
		case .file, .fileURL:
			let media = JSQDataMediaItem(maskAsOutgoing: !message.isIncoming)
			self.init(senderId: id, senderDisplayName: "", date: Date(), media: media)
		}
		self.message = message
	}
	
	convenience init(senderId id: String, text: String) {
		self.init(senderId: id, senderDisplayName: "", date: Date(), text: text)
	}
	
	convenience init(senderId id: String, media: JSQMediaItem) {
		self.init(senderId: id, senderDisplayName: "", date: Date(), media: media)
	}
	
	var isSystem: Bool {
		return senderId == ChatConstants.systemSenderId
	}
	
	var isIncoming: Bool {
		return senderId == ChatConstants.incomingSenderId
	}
	
	var isOutgoing: Bool {
		return senderId == ChatConstants.outgoingSenderId
	}
}

private extension Message {
	
	var isDataMessage: Bool {
		switch content {
		case .file, .fileURL:
			return true
		default:
			return false
		}
	}
}

// MARK: JSQMessagesCollectionViewCell+Resend

extension JSQMessagesCollectionViewCell {
	
	open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		guard let collectionView = superview as? UICollectionView else {
			return false
		}
		return collectionView.delegate?.collectionView?(collectionView, canPerformAction: action, forItemAt: collectionView.indexPath(for: self)!, withSender: sender) ?? false
	}
	
	func resend(_ sender: Any) {
		guard let collectionView = superview as? UICollectionView else {
			return
		}
		
		collectionView.delegate?.collectionView?(collectionView, performAction: #selector(resend(_:)), forItemAt: collectionView.indexPath(for: self)!, withSender: sender)
	}
	
}

// MARK: - ChatViewController

class ChatViewController: JSQMessagesViewController {
	
	weak var chat: ChatRoom? {
		didSet {
			guard oldValue != chat else {
				return
			}
			
			oldValue?.unsubscribe(self)
			chat?.subscribe(self)
			clearChat()
			showChatStatus()
		}
	}
	
	fileprivate var messages = [ChatMessage]()
	fileprivate var failedMessages = [Message]()
	
	private var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .messageBubbleIncoming)!
	private var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .messageBubbleOutgoing)!
	private var failedBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .messageBubbleFailed)!
	private var systemBubble = SystemMessagesBubbleImage()
	
	// MARK: - View Controller Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = chat?.name
		
		if #available(iOS 11.0, *) {
			collectionView.contentInsetAdjustmentBehavior = .never
		}
		
		collectionView.backgroundColor = .black
		inputToolbar.contentView.textView.keyboardAppearance = .dark
		inputToolbar.contentView.textView.backgroundColor = .black
		inputToolbar.contentView.textView.textColor = .white
		inputToolbar.contentView.textView.tintColor = .defaultTint
		inputToolbar.contentView.rightBarButtonItem.setTitleColor(.defaultTint, for: .normal)
		inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor.defaultTint.withAlphaComponent(0.3), for: .highlighted)
		inputToolbar.barStyle = .blackTranslucent
		
		collectionView.register(JSQMessagesCollectionViewCellSystem.nib(),
		                        forCellWithReuseIdentifier: JSQMessagesCollectionViewCellSystem.cellReuseIdentifier())
		
		collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
		collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
		
		senderId = ChatConstants.outgoingSenderId
		senderDisplayName = ""
		
		clearChat()
		showChatStatus()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.inputToolbar.contentView.textView.becomeFirstResponder()
	}
	
	/// Used to handle new `size` while rotating the device.
	/// `view.bounds` are accidentally incorrect straight after device rotation.
	private var actualViewSize: CGSize?
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		actualViewSize = size
		super.viewWillTransition(to: size, with: coordinator)
	}
	
	private func clearChat() {
		messages = []
		collectionView?.reloadData()
		collectionView?.layoutIfNeeded()
	}
	
	private func showChatStatus() {
		if let chat = chat {
			let text = chat.isEmpty ? "no_interlocutor".localized : "has_interlocutor".localized
			receive(ChatMessage(senderId: ChatConstants.systemSenderId, text: text))
		}
	}
	
	@IBAction func closeChat() {
		
		let confirmationHandler: (() -> ())? = { [weak self] in
			self?.chat = nil
			self?.performSegue(withIdentifier: "closeChat", sender: nil)
		}
		
		let confirmationWithExportHandler: (() -> ())? = { [weak self] in
			self?.exportChat() { exported in
				if exported {
					confirmationHandler?()
				}
			}
		}
		
		self.present(alert: UIAlerts.leavingChat(confirm: confirmationHandler, exportAndConfirm: confirmationWithExportHandler, deny: nil), animated: true)
	}
	
	// MARK: - Chat exporting
		
	@IBOutlet weak var exportButton: UIBarButtonItem!
	
	@IBAction private func exportChat() {
		exportChat(completion: { _ in })
	}
	
	private func exportChat(completion: @escaping (Bool) -> ()) {
		guard let chat = chat else {
			return
		}
		
		guard let path = UIKit.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			self.present(alert: UIErrors.genericError, animated: true)
			return
		}
		
		let fileURL = path.appendingPathComponent(chat.name).appendingPathExtension("txt")
		
		exportButton.isEnabled = false
		
		DispatchQueue.global().async { [weak self] in
			guard (try? self?.dumpChat().write(to: fileURL, atomically: false, encoding: .utf8)) != nil else {
				DispatchQueue.main.async {
					self?.present(alert: UIErrors.genericError, animated: true)
				}
				return
			}
			
			let share = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			share.completionWithItemsHandler = { _, completed, _, _ in
				try? UIKit.FileManager.default.removeItem(at: fileURL)
				DispatchQueue.main.async {
					completion(completed)
				}
			}
			
			DispatchQueue.main.async {
				self?.exportButton?.isEnabled = true
				
				if let popover = share.popoverPresentationController {
					popover.barButtonItem = self?.navigationItem.leftBarButtonItem
					popover.permittedArrowDirections = .up
				}
				
				self?.present(share, animated: true)
			}
		}
	}
	
	private func dumpChat() -> String {
		var dump = ""
		for chatMessage in messages {
			let format: String
			let text: String
			if chatMessage.isSystem {
				format = "chat_dump_system_message_format".localized
				text = chatMessage.text
			} else {
				format = (chatMessage.isIncoming ? "chat_dump_incoming_message_format" : "chat_dump_outgoing_message_format").localized
				if let message = chatMessage.message {
					switch message.content {
					case .text(let content):
						text = content
					case .file, .fileURL:
						text = "chat_dump_file_tranfer".localized
					}
				} else {
					text = "chat_dump_message_serialization_faild".localized
				}
			}
			dump += (dump.isEmpty ? "" : "\n") + String(format: format, text)
		}
		
		return dump
	}
	
	// MARK: - Sending / receiving messages
	
	private var sendingMessagesCount = 0 {
		didSet {
			if sendingMessagesCount == 0 {
				self.navigationController?.showProgress(percentage: 100, duration: 0.1)
				self.navigationController?.hideProgress()
			} else {
				self.navigationController?.showProgress(percentage: Double(90 / sendingMessagesCount))
			}
		}
	}
	
	private func isMessageFailed(_ message: Message) -> Bool {
		return failedMessages.contains(where: { $0 === message })
	}
	
	fileprivate func send(_ message: Message) {
		sendingMessagesCount += 1
		
		messages.append(ChatMessage(message: message))
		finishSendingMessage(animated: true)
		
		chat?.send(message: message) { [weak self] error in
			guard let `self` = self else {
				return
			}
			
			self.sendingMessagesCount -= 1
			
			let soundId = (error == nil) ? Constants.sentMessageSound : Constants.errorSound
			playSystemSound(with: soundId)
			
			guard error == nil else {
				if !self.isMessageFailed(message) {
					self.failedMessages.append(message)
					self.reloadCell(for: message)
				}
				
				return
			}
			
			if let index = self.failedMessages.index(where: { $0 === message }) {
				self.failedMessages.remove(at: index)
				self.reloadCell(for: message)
			}
		}
	}
	
	fileprivate func resend(at indexPath: IndexPath) {
		guard let message = messages[indexPath.item].message else {
			return
		}
		
		messages.remove(at: indexPath.item)
		collectionView.reloadData()
		
		send(message)
	}
	
	fileprivate func receive(_ message: Message) {
		playSystemSound(with: Constants.receivedMessageSound)
		receive(ChatMessage(message: message))
	}
	
	fileprivate func receive(_ message: ChatMessage) {
		messages.append(message)
		finishReceivingMessage(animated: true)
	}
	
	override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
		let message = Message(content: .text(text), incoming: false)
		send(message)
	}
	
	override func didPressAccessoryButton(_ sender: UIButton) {
		let filePicker = FilePickerController(delegate: self)
		if let popover = filePicker.alertController.popoverPresentationController {
			popover.sourceView = sender
			popover.sourceRect = sender.bounds
			popover.permittedArrowDirections = .down
		}
		present(filePicker, animated: false)
	}
	
	private func reloadCell(for message: Message) {
		if let index = self.messages.index(where: { $0.message === message }) {
			UIView.performWithoutAnimation {
				self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
			}
		}
	}
	
	// MARK: - JSQMessagesCollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return messages.count
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
		return messages[indexPath.item]
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
		
		let bubble: JSQMessageBubbleImageDataSource
		
		switch messages[indexPath.item].senderId {
		case ChatConstants.outgoingSenderId:
			if let message = messages[indexPath.item].message {
				bubble = isMessageFailed(message) ? failedBubble : outgoingBubble
			} else {
				bubble = outgoingBubble
			}
		case ChatConstants.incomingSenderId:
			bubble = incomingBubble
		default:
			bubble = systemBubble
		}
		
		return bubble
	}
	
	// MARK: - UICollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let chatMessage = messages[indexPath.item]
		
		if chatMessage.isSystem {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JSQMessagesCollectionViewCellSystem.cellReuseIdentifier(), for: indexPath) as! JSQMessagesCollectionViewCellSystem
			
			cell.text = chatMessage.text
			cell.backgroundColor = .clear
			
			return cell
		}
		
		if let message = chatMessage.message, message.isDataMessage {
			(chatMessage.media as? JSQDataMediaItem)?.isFailed = isMessageFailed(message)
		}
		
		let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
		
		if let messageCell = cell as? JSQMessagesCollectionViewCell {
			let textColor: UIColor = chatMessage.senderId == self.senderId ? .black : .white
			messageCell.textView?.textColor = textColor
			
			// Disabling user interaction and (unfortunately) data detectors to prevent text selection.
			// Such solution is caused by strange `UITextView` behavior inside a message bubble.
			// For more info about the problem see the following issue:
			// https://github.com/jessesquires/JSQMessagesViewController/issues/1159
			messageCell.textView?.isUserInteractionEnabled = false
			messageCell.textView?.dataDetectorTypes = UIDataDetectorTypes(rawValue: 0)
		}
		
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		var size = super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
		if messages[indexPath.item].isSystem {
			size.height = 20
		}
		let viewSize = actualViewSize ?? self.view.frame.size
		size.width = viewSize.width - 8
		return size
		
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
		guard let message = messages[indexPath.item].message else {
			return
		}
		
		let share: UIActivityViewController
		
		switch message.content {
		case .file(let data, let uti):
			guard let path = UIKit.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
				self.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			let fileExtension = FileManager.extractExtension(using: uti ?? "")
			let fileName = (Date.timeIntervalSinceReferenceDate * 10).description
			let fileURL = path.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
			
			guard (try? data.write(to: fileURL)) != nil else {
				self.present(alert: UIErrors.genericError, animated: true)
				return
			}
			
			share = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			share.completionWithItemsHandler = { _ in
				try? UIKit.FileManager.default.removeItem(at: fileURL)
			}
		case .fileURL(let url):
			share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
		default:
			return
		}
		
		if let popover = share.popoverPresentationController {
			guard let cell = collectionView.cellForItem(at: indexPath) as? JSQMessagesCollectionViewCell else {
				return
			}
			
			popover.sourceView = cell.messageBubbleContainerView
			popover.sourceRect = cell.messageBubbleContainerView.bounds
		}
		
		self.present(share, animated: true)
	}
	
	// MARK: - Handling `resend` menu action
	
	private var selectedMediaMessageIndexPathForMenu: IndexPath?
	
	override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
		super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
		let resendItem = UIMenuItem(title: "resend".localized, action: #selector(JSQMessagesCollectionViewCell.resend(_:)))
		UIMenuController.shared.menuItems = [resendItem]
		let chatMessage = messages[indexPath.item]
		if let message = chatMessage.message, message.isDataMessage, isMessageFailed(message) {
			selectedMediaMessageIndexPathForMenu = indexPath
		} else {
			selectedMediaMessageIndexPathForMenu = nil
		}
		return !chatMessage.isSystem
	}
	
	override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
		guard let message = messages[indexPath.item].message else {
			return false
		}
		
		let canCopy = action == #selector(copy(_:)) && !message.isDataMessage
		let canResend = action == #selector(JSQMessagesCollectionViewCell.resend(_:)) && isMessageFailed(message)
		return canCopy || canResend
	}
	
	override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
		if action == #selector(JSQMessagesCollectionViewCell.resend(_:)) {
			resend(at: indexPath)
			return
		}
		super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
	}
	
	override func didReceiveMenuWillShow(_ notification: Notification!) {
		guard let indexPath = selectedMediaMessageIndexPathForMenu else {
			super.didReceiveMenuWillShow(notification)
			return
		}
		
		NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillShowMenu, object: nil)
		
		guard let menu = notification.object as? UIMenuController else {
			return
		}
		
		menu.setMenuVisible(false, animated: false)
		
		guard let cell = collectionView.cellForItem(at: indexPath) as? JSQMessagesCollectionViewCell else {
			return
		}
		
		let bubbleRect = cell.convert(cell.messageBubbleContainerView.frame, to: self.view)
		
		menu.setTargetRect(bubbleRect, in: self.view)
		menu.setMenuVisible(true, animated: true)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMenuWillShow(_:)), name: .UIMenuControllerWillShowMenu, object: nil)
	}
	
	override func didReceiveMenuWillHide(_ notification: Notification!) {
		super.didReceiveMenuWillHide(notification)
		selectedMediaMessageIndexPathForMenu = nil
	}
}

// MARK: - ChatRoomDelegate

extension ChatViewController: ChatRoomDelegate {
	
	func chatRoom(_ chatRoom: ChatRoom, didReceive message: Message) {
		guard chatRoom == chat else {
			return
		}
		
		receive(message)
	}
	
	func chatRoomDidJoin(_ chatRoom: ChatRoom) {
		guard chatRoom == chat else {
			return
		}
		
		receive(ChatMessage(senderId: ChatConstants.systemSenderId, text: "event_chat_join".localized))
	}
	
	func chatRoomDidLeave(_ chatRoom: ChatRoom) {
		guard chatRoom == chat else {
			return
		}
		
		receive(ChatMessage(senderId: ChatConstants.systemSenderId, text: "event_chat_leave".localized))
	}
	
	func chatRoom(_ chatRoom: ChatRoom, connectionDidChange connected: Bool) {
		guard chatRoom == chat else {
			return
		}
		
		let text = connected ? "connection_established".localized : "connection_lost".localized
		receive(ChatMessage(senderId: ChatConstants.systemSenderId, text: text))
	}
	
	func chatRoom(_ chatRoom: ChatRoom, didReceive error: Error) {
		guard chatRoom == chat else {
			return
		}
		
		let placeholder = "file".localized.capitalized
		present(alert: UIErrors.fileDownloadFailed(filePlaceholder: placeholder), animated: true)
	}
}

// MARK: - FilePickerDelegate

extension ChatViewController: FilePickerDelegate {
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data, withUTI uti: String?) {
		
		let message = Message(content: .file(data, uti: uti), incoming: false)
		send(message)
	}
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
		
		let message = Message(content: .fileURL(url), incoming: false)
		send(message)
	}
	
	func filePickerHasFailed(_ controller: FilePickerController) {
		present(alert: UIErrors.genericError, animated: true)
	}
}
