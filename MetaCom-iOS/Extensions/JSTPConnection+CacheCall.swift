//
//  JSTPConnection+CacheCall.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 27.07.2017.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation
import JSTP

extension JSTP.Connection {
	
	func cacheCall(_ interface: String, _ method: String, _ parameters: Array<Value>, _ callback: Callback?) {
		
		var tokens: [NSObjectProtocol] = []
		let center = NotificationCenter.default
		
		let token = center.addObserver(forName: .MCConnectionRestored, object: self, queue: nil) { _ in
			
			tokens.forEach(center.removeObserver)
			tokens.removeAll()
			
			self.cacheCall(interface, method, parameters, callback)
		}
		
		let erasingCallback: Callback? = { values, error in
			
			tokens.forEach(center.removeObserver)
			tokens.removeAll()
			callback?(values, error)
		}
		
		tokens.append(token)
		
		call(interface, method, parameters, erasingCallback)
	}
}

