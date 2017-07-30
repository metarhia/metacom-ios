//
//  ChatViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
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
	
	var isSystem: Bool {
		return senderId == ChatConstants.systemSenderId
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
		}
	}
	
	fileprivate var messages = [ChatMessage]()
	fileprivate var failedMessages = [Message]()
	
	private var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .jsq_messageBubbleLightGray())!
	private var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .jsq_messageBubbleBlue())!
	private var failedBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .jsq_messageBubbleRed())!
	private var systemBubble = SystemMessagesBubbleImage()
	
	// MARK: - View Controller Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = chat?.name
		
		collectionView.register(JSQMessagesCollectionViewCellSystem.nib(),
		                        forCellWithReuseIdentifier: JSQMessagesCollectionViewCellSystem.cellReuseIdentifier())
		
		collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
		collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
		
		senderId = ChatConstants.outgoingSenderId
		senderDisplayName = ""
		
		clearChat()
		
		let resendItem = UIMenuItem(title: "Resend", action: #selector(JSQMessagesCollectionViewCell.resend(_:)))
		UIMenuController.shared.menuItems = [resendItem]
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.inputToolbar.contentView.textView.becomeFirstResponder()
	}
	
	private func clearChat() {
		messages = []
		collectionView?.reloadData()
		collectionView?.layoutIfNeeded()
	}
	
	@IBAction func closeChat() {
		let confirmationBlock: (() -> ())? = { [weak self] in
			self?.performSegue(withIdentifier: "closeChat", sender: nil)
		}
		
		self.present(alert: UIAlerts.leavingChat(confirm: confirmationBlock, deny: nil), animated: true)
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
		
		let sendingMessageIndex = messages.count
		messages.append(ChatMessage(message: message))
		finishSendingMessage(animated: true)
		
		chat?.send(message: message) { [weak self] error in
			guard let `self` = self else {
				return
			}
			
			self.sendingMessagesCount -= 1
			
			guard error == nil else {
				self.failedMessages.append(message)
				UIView.performWithoutAnimation {
					self.collectionView.reloadItems(at: [IndexPath(item: sendingMessageIndex, section: 0)])
				}
				return
			}
		}
	}
	
	// Perhaps this method will be removed later.
	fileprivate func resend(at indexPath: IndexPath) {
		guard let message = messages[indexPath.item].message else {
			return
		}
		
		messages.remove(at: indexPath.item)
		
		resend(message)
	}
	
	fileprivate func resend(_ message: Message) {
		if let index = failedMessages.index(where: { $0 === message }) {
			failedMessages.remove(at: index)
		}
		
		collectionView.reloadData()
		send(message)
	}
	
	fileprivate func receive(_ message: Message) {
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
		present(filePicker, animated: false)
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
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JSQMessagesCollectionViewCellSystem.cellReuseIdentifier(), for: indexPath) as! JSQMessagesCollectionViewCell
			
			cell.textView.text = chatMessage.text
			cell.textView.textColor = .lightGray
			cell.textView.textAlignment = .center
			cell.textView.font = UIFont.preferredFont(forTextStyle: .body).withSize(15)
			cell.textView.textContainerInset = .zero
			cell.textView.isUserInteractionEnabled = false
			
			return cell
		}
		
		if let message = chatMessage.message, message.isDataMessage {
			(chatMessage.media as? JSQDataMediaItem)?.isFailed = isMessageFailed(message)
		}
		
		let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
		
		if let messageCell = cell as? JSQMessagesCollectionViewCell {
			let textColor: UIColor = chatMessage.senderId == self.senderId ? .white : .black
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
		return size
		
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
		// TODO: Handle tap on message if it contains `JSQDataMediaItem`
		//		guard let media = messages[indexPath.item].media else {
		//			return
		//		}
	}
	
	// MARK: - Handling `resend` menu action
	
	private var selectedMediaMessageIndexPathForMenu: IndexPath?
	
	override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
		super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
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
		
		if let message = ChatMessage(senderId: ChatConstants.systemSenderId, displayName: "", text: "Somebody has joined the chat") {
			receive(message)
		}
	}
	
	func chatRoomDidLeave(_ chatRoom: ChatRoom) {
		guard chatRoom == chat else {
			return
		}
		
		if let message = ChatMessage(senderId: ChatConstants.systemSenderId, displayName: "", text: "Somebody has left the chat") {
			receive(message)
		}
	}
	
}

// MARK: - FilePickerDelegate

extension ChatViewController: FilePickerDelegate {
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data, withUTI uti: String?) {
		
		let message = Message(content: .file(data, type: uti), incoming: false)
		send(message)
	}
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
		
		let message = Message(content: .fileURL(url), incoming: false)
		send(message)
	}
}
