//
//  Persistence.swift
//  DataDriven (iOS)
//
//  Created by Tomas Reimers on 12/26/21.
//

import Foundation
import WatchConnectivity

let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
let storagePath = libraryDirectory!.appendingPathComponent("shortcuts.json")

//@MainActor
class Persistence: NSObject, ObservableObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // No-op
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // No-op
    }
    
    @Published var isLoading = false
    @Published var shortcuts = [Shortcut]()
    
    override init() {
        super.init()
        
        let session = WCSession.default;
        session.delegate = self
        session.activate()
    }
    
    func loadFromDisk() async {
        isLoading = true;
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: storagePath.path) {
            do {
                let data = try Data(contentsOf: storagePath)
                shortcuts = try JSONDecoder().decode([Shortcut].self, from: data)
            } catch { print(error) }
        } else {
            shortcuts = []
        }
        
        
        isLoading = false
    }
    
    func createShortcut(shortcut: Shortcut) async {
        shortcuts.append(shortcut)
        await saveToDisk()
    }
    
    func deleteShortcut(id: String) async {
        shortcuts.removeAll(where: { $0.id == id })
        await saveToDisk();
    }
    
    func saveToDisk() async {
        do {
            let jsonData = try JSONEncoder().encode(shortcuts)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            try jsonString.write(to: storagePath, atomically: true, encoding: .utf8)
        } catch { print(error) }
    }
    
    func sendToWatch() async {
        await saveToDisk()
        
        let session = WCSession.default;
        session.transferFile(storagePath, metadata: [:])
    }
}
