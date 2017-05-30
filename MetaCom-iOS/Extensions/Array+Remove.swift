//
//  Array+Remove.swift
//  MetaCom-iOS
//
//  Created by iKing on 30.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
	
	@discardableResult mutating func remove(_ object: Element) -> Bool {
		if let index = index(of: object) {
			remove(at: index)
			return true
		}
		return false
	}
}
