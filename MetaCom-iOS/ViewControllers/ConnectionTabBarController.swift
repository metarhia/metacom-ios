//
//  ConnectionTabBarController.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 04.08.2017.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class ConnectionTabBarController: UITabBarController {
	
	@IBAction func disconnect() {
		
		let confirmation = {
			self.performSegue(withIdentifier: "unwind_to_connection", sender: nil)
		}
		
		present(alert: UIAlerts.leavingServer(confirm: confirmation, deny: nil), animated: true)
	}
}
