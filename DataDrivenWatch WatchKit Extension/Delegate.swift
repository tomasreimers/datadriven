//
//  Delegate.swift
//  DataDrivenWatch WatchKit Extension
//
//  Created by Tomas Reimers on 12/29/21.
//

import WatchKit
import ClockKit

let BACKGROUND_REFRESH_IDENTIFIER = "BACKGROUND_REFRESH_TASK"

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    var sessionIdToTask: [String:WKURLSessionRefreshBackgroundTask] = [:]
    
    func applicationDidFinishLaunching() {
        scheduleRefreshInAHalfHour()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let fileTransferTask as WKWatchConnectivityRefreshBackgroundTask:
                globalWatchSessionDelegate.markTasksAsCompleteWhenDone(task: fileTransferTask)
                break
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                Task {
                    let complications = await CLKComplicationServer.sharedInstance().getActiveComplications()
                    
                    if (complications.count > 0) {
                        let shortcuts = loadFromDisk()
                        var shortcutById: [String:Shortcut] = [:]
                        shortcuts.forEach {
                            shortcut in
                            shortcutById[shortcut.id] = shortcut
                        }
                        
                        let configuration = URLSessionConfiguration
                            .background(withIdentifier: BACKGROUND_REFRESH_IDENTIFIER)
                        configuration.isDiscretionary = true
                        configuration.sessionSendsLaunchEvents = true
                        
                        let session = URLSession(configuration: configuration,
                                                 delegate: self, delegateQueue: nil)
                        
                        var downloadTasks: [URLSessionDownloadTask] = []
                        
                        complications.forEach {
                            complication in
                            
                            let defn = shortcutById[complication.identifier]
                            
                            if (defn != nil) {
                                let url = URL(string: defn!.url)
                                if (url != nil) {
                                    let downloadTask = session.downloadTask(with: url!)
                                    downloadTasks.append(downloadTask)
                                }
                            }
                        }
                        
                        downloadTasks.forEach {
                            downloadTask in
                            downloadTask.resume()
                        }
                    }
                
                    scheduleRefreshInAHalfHour()
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
                break;
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                sessionIdToTask[urlSessionTask.sessionIdentifier] = urlSessionTask
                let configuration = URLSessionConfiguration
                    .background(withIdentifier: urlSessionTask.sessionIdentifier)
                let _ = URLSession(configuration: configuration,
                                   delegate: self, delegateQueue: nil)
                break;
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = try! Data(contentsOf: location)
        let originalRequest = downloadTask.originalRequest
        if (originalRequest?.url != nil) {
            saveDataFromFetch(url: originalRequest!.url!, data: data)

        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task {
            await reloadComplicationsAndSetNewSyncedValue()
            let task = sessionIdToTask[session.configuration.identifier ?? "MISSING_ID"]

            if (task != nil) {
                task!.setTaskCompletedWithSnapshot(false)
            }

        }
    }
}

func scheduleRefreshInAHalfHour() {
    let halfHourOut = Date().addingTimeInterval(30 * 60)
    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: halfHourOut, userInfo: nil) { error in
        print(error ?? "")
    }
}
