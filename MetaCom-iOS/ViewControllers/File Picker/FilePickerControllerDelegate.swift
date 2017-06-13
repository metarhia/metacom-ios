//
//  FilePickerControllerDelegate.swift
//  MetaCom-iOS
//
//  Created by iKing on 12.06.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

protocol FilePickerControllerDelegate: class {
	
	func filePicker(_ controller: FilePickerController, didPickFileAt url: URL)
	
	func filePicker(_ controller: FilePickerController, didPickData data: Data)
}
