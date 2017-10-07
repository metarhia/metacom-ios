//
//  AppDelegate.swift
//  MetaCom-iOS
//
//  Created by Artem Chernenkiy on 17.05.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	var isSoundEnabled = true
	
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
				
		NotificationCenter.default.addObserver(RemotesManager.shared,
		                                       selector: #selector(RemotesManager.storeDidChange(_:)),
		                                       name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
		                                       object: NSUbiquitousKeyValueStore.default())
		NSUbiquitousKeyValueStore.default().synchronize()
		
		setSoundAvailability()
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		
		setSoundAvailability()
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

extension AppDelegate {
	
	fileprivate func setSoundAvailability() {
		
		DispatchQueue.main.async {
			let rawValue = UserDefaults.standard.object(forKey: "enabled_preference") as? NSNumber
			self.isSoundEnabled = Bool(rawValue ?? 1)
		}
	}
}
