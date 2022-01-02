//
//  Persistence.swift
//  DataDriven (iOS)
//
//  Created by Tomas Reimers on 12/26/21.
//

import Foundation
import WatchConnectivity
import ClockKit

let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
let storagePath = libraryDirectory!.appendingPathComponent("shortcuts.json")

func loadFromDisk() -> [Shortcut] {
    var shortcuts = [Shortcut]();
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: storagePath.path) {
        do {
            let data = try Data(contentsOf: storagePath)
            shortcuts = try JSONDecoder().decode([Shortcut].self, from: data)
        } catch { print(error) }
    } else {
        shortcuts = []
    }
    
    return shortcuts;
}

func saveReceivedToDisk(url: URL) -> Task<(), Never> {
    if (FileManager.default.fileExists(atPath: storagePath.path)) {
        try! FileManager.default.removeItem(at: storagePath)
    }
    try! FileManager.default.moveItem(at: url, to: storagePath)
    
    return Task {
        clearUnneededUserDefaults()
        await syncDataInForeground()
        
        CLKComplicationServer.sharedInstance().reloadComplicationDescriptors()
    }
}

let LAST_SYNCED_KEY = "lastSynced"

func clearUnneededUserDefaults() {
    let shortcuts = loadFromDisk()
    var shortcutIds: [String] = [LAST_SYNCED_KEY]
    shortcuts.forEach {
        shortcut in
        shortcutIds.append(shortcut.id)
    }
    
    UserDefaults.standard.dictionaryRepresentation().keys.forEach {
        key in
        if (!shortcutIds.contains(key)) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

func getComplicationValue(id: String) -> String {
    return UserDefaults.standard.string(forKey: id) ?? "?"
}

func updateComplicationValue(id: String, value: String) {
    UserDefaults.standard.set(value, forKey: id)
}

func updateLastSyncedValue(value: Date) {
    UserDefaults.standard.set(value.timeIntervalSince1970, forKey: LAST_SYNCED_KEY)
}

func getLastSyncedValue() -> Date? {
    let lastSyncedTimeInterval = UserDefaults.standard.double(forKey: LAST_SYNCED_KEY);
    return lastSyncedTimeInterval != 0 ? Date(timeIntervalSince1970: lastSyncedTimeInterval) : nil;
}
