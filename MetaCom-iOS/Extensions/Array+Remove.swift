//
//  Array+Remove.swift
//  MetaCom-iOS
//
//  Created by iKing on 30.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
	
	mutating func remove(_ object: Element) {
		if let index = index(of: object) {
			remove(at: index)
		}
	}
}
