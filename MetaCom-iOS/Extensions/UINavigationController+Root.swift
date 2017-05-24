//
//  UINavigationController+Root.swift
//  MetaCom-iOS
//
//  Created by iKing on 24.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UINavigationController {
	
	var rootViewController: UIViewController? {
		return viewControllers.first
	}
	
}
