//
//  NotificationName+Extensions.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 20.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

extension Notification.Name {
	
	static let MCConnectionEstablished = Notification.Name(rawValue: "metacom.connection.wasEstablished")
	static let MCConnectionDidReceive = Notification.Name(rawValue: "metacom.connection.didReceiveData")
	static let MCConnectionRestored = Notification.Name(rawValue: "metacom.connection.wasRestored")
	static let MCConnectionLost = Notification.Name(rawValue: "metacom.connection.wasLost")
	static let MCConnectionDidFail = Notification.Name(rawValue: "metacom.connection.didFail")
}
