//
//  String+Trim.swift
//  MetaCom-iOS
//
//  Created by iKing on 24.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

extension String {
	
	/**
		Returns a new string made by removing from both ends of the String whitespaces and newlines.
	*/
	func trim() -> String {
		return self.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}
