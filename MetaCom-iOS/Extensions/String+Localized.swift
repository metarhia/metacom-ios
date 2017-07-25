//
//  String+Localized.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 07.07.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

extension String {
	
	func localized(in bundle: Bundle = Bundle.main, table: String?) -> String {
		return bundle.localizedString(forKey: self, value: self, table: table)
	}
	
	var localized: String {
		return localized(table: "Localizable")
	}
}
