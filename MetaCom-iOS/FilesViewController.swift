//
//  FilesViewController.swift
//  MetaCom-iOS
//
//  Created by iKing on 19.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

class FilesViewController: UIViewController {
	
	@IBAction func upload() {
		let alert = UIAlertController(title: "Upload",
		                              message: "Your file was uploaded. Code is 31415926535.",
		                              preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
	
	@IBAction func download() {
		let alert = UIAlertController(title: "Enter download code:",
		                              message: nil,
		                              preferredStyle: .alert)
		alert.addTextField { textField in
			// TODO: Setup `textField`
		}
		alert.addAction(UIAlertAction(title: "Download", style: .default))
		present(alert, animated: true)
	}

}
