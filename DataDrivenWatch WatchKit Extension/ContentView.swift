//
//  ContentView.swift
//  DataDrivenWatch WatchKit Extension
//
//  Created by Tomas Reimers on 12/26/21.
//

import SwiftUI

struct ContentView: View {    
    @State var lastUpdated = lastUpdatedDateToString(date: getLastSyncedValue())
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let wcDelegate = globalWatchSessionDelegate
        
    var body: some View {
        VStack {
            VStack {
                Button("Sync") {
                    Task {
                        await syncDataInForeground()
                        self.lastUpdated = lastUpdatedDateToString(date: getLastSyncedValue())
                    }
                }
            }
            .padding()
            .frame(maxHeight:.infinity)
            Text(lastUpdated)
                .multilineTextAlignment(.center)
        }.frame(width: .infinity, height: .infinity)
            .ignoresSafeArea( edges:[.bottom]).onReceive(timer) { input in
                self.lastUpdated = lastUpdatedDateToString(date: getLastSyncedValue())
            }
        
    }
        
}

func lastUpdatedDateToString(date: Date?) -> String {
    if (date == nil) {
        return "Never synced"
    }
        
    let diffSinceNow = Date().timeIntervalSince(date!)
    if (diffSinceNow > 24 * 60 * 60) {
        return String(format: "Synced %dd ago", Int(diffSinceNow / (24 * 60 * 60)))
    } else if (diffSinceNow > 60 * 60) {
        return String(format: "Synced %dh ago", Int(diffSinceNow / (60 * 60)))
    } else if (diffSinceNow > 60) {
        return String(format: "Synced %dm ago", Int(diffSinceNow / 60))
    } else if (diffSinceNow > 0) {
        return String(format: "Synced %ds ago", Int(diffSinceNow))
    } else {
        return "Synced just now"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
