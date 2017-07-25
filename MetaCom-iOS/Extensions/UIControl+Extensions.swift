//
//  UIControl+Extensions.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 09.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

extension UIControl {
	
	private class ClosureWrapper {
		
		let closure: () -> ()
		
		init(owner: AnyObject, block: @escaping () -> ()) {
			closure = block
			objc_setAssociatedObject(owner, "\(owner.description)\(arc4random())", self, .OBJC_ASSOCIATION_RETAIN)
		}
		
		@objc func run() {
			closure()
		}
	}
	
	func addAction(for controlEvents: UIControlEvents, action: @escaping () -> ()) {
		let wrapper = ClosureWrapper(owner: self, block: action)
		addTarget(wrapper, action: #selector(ClosureWrapper.run), for: controlEvents)
	}
}
