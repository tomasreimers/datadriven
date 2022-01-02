//
//  SyncData.swift
//  DataDrivenWatch WatchKit Extension
//
//  Created by Tomas Reimers on 12/27/21.
//

import Foundation
import ClockKit

func syncDataInForeground() async {
    let shortcuts = loadFromDisk()
    shortcuts.forEach {
        shortcut in
        if let url = URL(string: shortcut.url) {
           URLSession.shared.dataTask(with: url) { data, response, error in
               if let data = data {
                   saveDataToShortcut(shortcut: shortcut, data: data)
               }
           }.resume()
        }
    }
    
    await reloadComplicationsAndSetNewSyncedValue()
}

func saveDataToShortcut(shortcut: Shortcut, data: Data) {
    do {
        do {
            let value: String = try getValue(from: data, field: shortcut.key)
            updateComplicationValue(id: shortcut.id, value: value)
        } catch DecodingError.typeMismatch {
            let value: Double = try getValue(from: data, field: shortcut.key)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedNumber = numberFormatter.string(from: NSNumber(value:value))
            updateComplicationValue(id: shortcut.id, value: formattedNumber!)
        }
    } catch let error {
        print(error)
    }
}

func saveDataFromFetch(url: URL, data: Data) {
    let shortcuts = loadFromDisk()
    shortcuts.forEach {
        shortcut in
        if url.path == shortcut.url {
            saveDataToShortcut(shortcut: shortcut, data: data)
        }
    }
}

func reloadComplicationsAndSetNewSyncedValue() async {
    await CLKComplicationServer.sharedInstance().getActiveComplications().forEach {
        complication in
        CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
    }
    
    updateLastSyncedValue(value: Date())
}

extension CLKComplicationServer {
    // Safely access the server's active complications.
    @MainActor
    func getActiveComplications() async -> [CLKComplication] {
        return await withCheckedContinuation { continuation in
            
            // First, set up the notification.
            let center = NotificationCenter.default
            let mainQueue = OperationQueue.main
            var token: NSObjectProtocol?
            token = center.addObserver(forName: .CLKComplicationServerActiveComplicationsDidChange, object: nil, queue: mainQueue) { _ in
                center.removeObserver(token!)
                continuation.resume(returning: self.activeComplications!)
            }
            
            // Then check to see if we have a valid active complications array.
            if activeComplications != nil {
                center.removeObserver(token!)
                continuation.resume(returning: self.activeComplications!)
            }
        }
    }
}

// FROM https://stackoverflow.com/a/53697879/781199

/// A structure that holds no fixed key but can generate dynamic keys at run time
struct GenericCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    static func makeKey(_ stringValue: String) -> GenericCodingKeys { return self.init(stringValue: stringValue)! }
    static func makeKey(_ intValue: Int) -> GenericCodingKeys { return self.init(intValue: intValue)! }
}

/// A structure that retains just the decoder object so we can decode dynamically later
fileprivate struct JSONHelper: Decodable {
    let decoder: Decoder

    init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}

func getValue<T: Decodable>(from json: Data, field: String) throws -> T {
    let helper = try JSONDecoder().decode(JSONHelper.self, from: json)
    let container = try helper.decoder.container(keyedBy: GenericCodingKeys.self)
    return try container.decode(T.self, forKey: .makeKey(field))
}
