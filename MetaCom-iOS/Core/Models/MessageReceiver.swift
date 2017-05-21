//
//  MessageReceiver.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 18.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

/**
	Protocol that handles message receiving.
*/
protocol MessageReceiver: class {
	
	func didJoin()
	func didLeave()
	func didReceive(_ message: Message)
}
