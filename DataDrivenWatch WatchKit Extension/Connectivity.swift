//
//  Connectivity.swift
//  DataDrivenWatch WatchKit Extension
//
//  Created by Tomas Reimers on 12/27/21.
//

import Foundation
import WatchConnectivity
import WatchKit

let globalWatchSessionDelegate = WatchSessionDelegate()

class WatchSessionDelegate : NSObject, WCSessionDelegate {
    var session: WCSession
    var tasksToMarkComplete: [WKWatchConnectivityRefreshBackgroundTask] = []

    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let task = saveReceivedToDisk(url: file.fileURL)

        Task {
            await task.result
            
            if (!session.hasContentPending) {
                for task in tasksToMarkComplete {
                    task.setTaskCompletedWithSnapshot(false)
                }
                tasksToMarkComplete.removeAll()
            }
        }
    }
    
    func markTasksAsCompleteWhenDone(task: WKWatchConnectivityRefreshBackgroundTask) {
        tasksToMarkComplete.append(task)
    }
}
