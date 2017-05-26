//
//  UIViewController+Content.swift
//  MetaCom-iOS
//
//  Created by iKing on 24.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIViewController {
	
	var content: UIViewController {
		if let navigation = self as? UINavigationController {
			return navigation.rootViewController ?? self
		}
		return self
	}
}
