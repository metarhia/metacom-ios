//
//  RemotesManager.swift
//  MetaCom-iOS
//
//  Created by iKing on 06.10.17.
//  Copyright © 2017 Metarhia. All rights reserved.
//

import Foundation

class RemotesManager {
	
	static let remotesDidChangeNotification: Notification.Name = Notification.Name("metacom.RemotesManager.remotesDidChange")
	
	private static let remotesDictionaryKey = "remotes"
	
	static let shared = RemotesManager()
	
	private init() {
		updateRemotes()
	}
	
	private var remotesStore: [(remote: Remote, date: Date)] = [] {
		didSet {
			NotificationCenter.default.post(name: RemotesManager.remotesDidChangeNotification, object: self)
		}
	}
	
	var remotes: [Remote] {
		return remotesStore.map { $0.remote }
	}
	
	func addRemote(_ remote: Remote) {
		if let index = remotesStore.index(where: { $0.remote == remote }) {
			remotesStore.remove(at: index)
		}
		remotesStore.insert((remote, Date()), at: 0)
		saveRemotes()
	}
	
	func removeRemote(_ remote: Remote) {
		if let index = remotesStore.index(where: { $0.remote == remote }) {
			remotesStore.remove(at: index)
		}
		saveRemotes()
	}
	
	func remotes(havingPrefix prefix: String) -> [Remote] {
		return remotes.filter { $0.connectionString.hasPrefix(prefix) }
	}
	
	@objc func storeDidChange(_ notification: Notification) {
		if let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
			reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
			
			removeOldRemotes()
		}
		
		if let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
			if keys.contains(RemotesManager.remotesDictionaryKey) {
				updateRemotes()
			}
		}
	}
	
	private func saveRemotes() {
		var remotes: [String: Date] = [:]
		remotesStore.forEach {
			remotes[$0.remote.connectionString] = $0.date
		}
		
		let store = NSUbiquitousKeyValueStore.default()
		store.set(remotes, forKey: RemotesManager.remotesDictionaryKey)
	}
	
	private func updateRemotes() {
		let store = NSUbiquitousKeyValueStore.default()
		guard let dictionary = store.dictionary(forKey: RemotesManager.remotesDictionaryKey) as? [String: Date] else {
			return
		}
		
		var remotes: [(remote: Remote, date: Date)] = []
		dictionary.forEach {
			if let remote = Remote(connectionString: $0.key) {
				remotes.append((remote, $0.value))
			}
		}
		remotes.sort { $0.date > $1.date }
		remotesStore = remotes
	}
	
	private func removeOldRemotes() {
		updateRemotes()
		remotesStore = Array(remotesStore[0..<(remotesStore.count / 2)])
		saveRemotes()
	}
}
