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

// MARK: - Initialization `JSQMessage` from `Message`

private extension JSQMessage {
	
	convenience init(message: Message) {
		// TODO: Handle messages with file content
		let id = message.isIncoming ? ChatConstants.incomingSenderId : ChatConstants.outgoingSenderId
		switch message.content {
		case .text(let text):
			self.init(senderId: id, displayName: "", text: text)
		case .file(let data, _):
			let media = JSQDataMediaItem(data: data, maskAsOutgoing: !message.isIncoming)
			self.init(senderId: id, displayName: "", media: media)
		case .fileURL(let url):
			let data = try? Data(contentsOf: url)
			let media = JSQDataMediaItem(data: data ?? Data(), maskAsOutgoing: !message.isIncoming)
			self.init(senderId: id, displayName: "", media: media)
		}
	}
}

private extension JSQMessage {
	
	var isSystem: Bool {
		return senderId == ChatConstants.systemSenderId
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
	
	fileprivate var messages = [JSQMessage]()
	
	private var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .jsq_messageBubbleLightGray())!
	private var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .jsq_messageBubbleBlue())!
	private var systemBubble = SystemMessagesBubbleImage()
	
	// MARK: - View Conrtroller Lifecycle
	
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
	
	fileprivate func send(_ message: Message) {
		sendingMessagesCount += 1
		chat?.send(message: message) { [weak self] error in
			guard let `self` = self else {
				return
			}
			
			self.sendingMessagesCount -= 1
			
			guard error == nil else {
				// TODO: Handle error. Maybe show an alert, make message bubble red etc.
				self.present(alert: UIErrors.messageSendingFailed, animated: true)
				return
			}
		}
		
		messages.append(JSQMessage(message: message))
		finishSendingMessage(animated: true)
		
		showFileLoadingIfNeeded()
	}
	
	fileprivate func receive(_ message: Message) {
		receive(JSQMessage(message: message))
	}
	
	fileprivate func receive(_ message: JSQMessage) {
		
		messages.append(message)
		finishReceivingMessage(animated: true)
		
		showFileLoadingIfNeeded()
	}
	
	// TODO: Temporary. For demonstration only.
	private func showFileLoadingIfNeeded() {
		if let media = messages.last?.media as? JSQDataMediaItem {
			media.setLoading(true)
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
				guard self != nil else {
					return
				}
				media.setLoading(false)
			}
		}
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
			bubble = outgoingBubble
		case ChatConstants.incomingSenderId:
			bubble = incomingBubble
		default:
			bubble = systemBubble
		}
		
		return bubble
	}
	
	// MARK: - UICollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let message = messages[indexPath.item]
		
		if message.isSystem {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JSQMessagesCollectionViewCellSystem.cellReuseIdentifier(), for: indexPath) as! JSQMessagesCollectionViewCell
			
			cell.textView.text = message.text
			cell.textView.textColor = .lightGray
			cell.textView.textAlignment = .center
			cell.textView.font = UIFont.preferredFont(forTextStyle: .body).withSize(15)
			cell.textView.textContainerInset = .zero
			
			return cell
		}
		
		let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
		
		if let messageCell = cell as? JSQMessagesCollectionViewCell {
			let textColor: UIColor = message.senderId == self.senderId ? .white : .black
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
		
		if let message = JSQMessage(senderId: ChatConstants.systemSenderId, displayName: "", text: "Somebody has joined the chat") {
			receive(message)
		}
	}
	
	func chatRoomDidLeave(_ chatRoom: ChatRoom) {
		guard chatRoom == chat else {
			return
		}
		
		if let message = JSQMessage(senderId: ChatConstants.systemSenderId, displayName: "", text: "Somebody has left the chat") {
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
