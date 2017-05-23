//
//  ChatViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit
import JSQMessagesViewController

// TODO: Replace with actual data model
private let Messages = [
	Message(content: .text("Hello"), incoming: true),
	Message(content: .text("Hi"), incoming: false),
	Message(content: .text("What's up?"), incoming: false),
	Message(content: .text("I'll answer with photo:"), incoming: true),
	Message(content: .file(Data()), incoming: true),
	Message(content: .text("Hmmm... Something gone wrong..."), incoming: false)
]

// MARK: - ChatViewController

class ChatViewController: JSQMessagesViewController {
	
	var messages = [JSQMessage]()
	private var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .jsq_messageBubbleLightGray())!
	private var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: .jsq_messageBubbleBlue())!

    override func viewDidLoad() {
        super.viewDidLoad()

		collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
		collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
		
		messages = Messages.map { JSQMessage(message: $0) }
		
		senderId = Constants.Chat.outcomingSenderId
		senderDisplayName = ""
		
		collectionView?.reloadData()
		collectionView?.layoutIfNeeded()
    }
	
	// Dark magic to send a reply message **********************************************************
	// Of course, will be removed.
	
	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			sendReply()
		}
	}
	
	func sendReply() {
		showTypingIndicator = !showTypingIndicator
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
			let message = JSQMessage(message: Message(content: .text("Hi there!"), incoming: true))
			self.messages.append(message)
			self.finishReceivingMessage(animated: true)
		}
	}
	
	// End of dark magic ***************************************************************************
	
	override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
		guard let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text) else {
			return
		}
		messages.append(message)
		finishSendingMessage(animated: true)
	}
	
	override func didPressAccessoryButton(_ sender: UIButton) {
		// TODO: Let user to upload file
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
			
			if message.senderId == self.senderId {
				messageCell.textView?.textColor = .white
			} else {
				messageCell.textView?.textColor = .black
			}
		}
		
		return cell
	}

}
