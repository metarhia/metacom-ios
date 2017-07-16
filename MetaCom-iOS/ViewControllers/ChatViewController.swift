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
}

// MARK: - Initialization `JSQMessage` from `Message`

extension JSQMessage {
	
	convenience init(message: Message) {
		// TODO: Handle messages with file content
		let id = message.isIncoming ? ChatConstants.incomingSenderId : ChatConstants.outgoingSenderId
		switch message.content {
		case .text(let text):
			self.init(senderId: id, displayName: "", text: text)
		case .file(let data):
			let media = JSQDataMediaItem(data: data, maskAsOutgoing: !message.isIncoming)
			self.init(senderId: id, displayName: "", media: media)
		}
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
	
	// MARK: - View Conrtroller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

		self.title = chat?.name
		
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
				self.present(UIAlertController.messageSendingFailed(), animated: true)
				return
			}
		}
		
		messages += [JSQMessage(message: message)]
		finishSendingMessage(animated: true)
		
		showFileLoadingIfNeeded()
	}
	
	fileprivate func receive(_ message: Message) {
		messages += [JSQMessage(message: message)]
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
	
	//MARK: - JSQMessagesCollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return messages.count
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
		return messages[indexPath.item]
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
		
		return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
	}
	
	//MARK: - UICollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
		
		if let messageCell = cell as? JSQMessagesCollectionViewCell {
			let message = messages[indexPath.item]
			
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
	
}

// MARK: - FilePickerDelegate

extension ChatViewController: FilePickerDelegate {
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data) {
		let message = Message(content: .file(data), incoming: false)
		send(message)
		
	}
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL) {
		// TODO: Upload
		let message = Message(content: .file(Data()), incoming: false)
		send(message)
	}
}
