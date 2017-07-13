//
//  MWSessionWorker.swift
//  SENDER
//
//  Created by Eugene Gilko on 8/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

class MWSessionWorker: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    override init() {
        super.init()

        let longSessionConfig = URLSessionConfiguration.default
        longSessionConfig.timeoutIntervalForRequest = 120
        self.addBaseSessionParameters(longSessionConfig)
        self.longSession = Foundation.URLSession(configuration: longSessionConfig, delegate: self, delegateQueue:OperationQueue.main)

        let sendSessionConfig = URLSessionConfiguration.default
        sendSessionConfig.timeoutIntervalForRequest = 30
        self.addBaseSessionParameters(sendSessionConfig)
        self.sendSession = Foundation.URLSession(configuration: sendSessionConfig, delegate: self, delegateQueue:OperationQueue.main)
    }

    var taskItemsQueue = [String:MWTaskItem]()
    var taskPreparedToSend = [MWTaskItem]()
    
    func runTest() {
        
        let taskItem = MWTaskItem()
        taskItem.initWIthURL(nil)
//        dispatch_barrier_sync(concurrentSendQueue) {
        
            self.taskPreparedToSend.append(taskItem)
            
//            dispatch_async(dispatch_get_main_queue(), { 
                self.runq()
//            })
//        }
    }
    
    func runq() {
//        dispatch_barrier_sync(concurrentSendQueue) {
            self.createRequestFromQueueItem(queueItem: self.taskPreparedToSend[0], useLongSession: false)
            self.taskPreparedToSend.remove(at: 0)
//        }
    }
    
//    private let concurrentSendQueue = dispatch_queue_create("com.MidleWare.Sender.sendQueue", DISPATCH_QUEUE_CONCURRENT)
    
    func runQueue() -> Void {
        
        if self.taskItemsQueue.count > 0 {
            let curTask = self.taskItemsQueue.values.first! as MWTaskItem
            self.createDataTask(curTask.useLongSession!, queueItem: curTask, request: curTask.storedRequest as URLRequest?)
        }
    }
    
    func createRequestFromQueueItem(queueItem: MWTaskItem?, useLongSession: Bool) -> Void {
        
        let request = RequestBuilder.shared.createPOSTRequest(queueItem: queueItem!, useLongSession: false)
        
        queueItem?.useLongSession = useLongSession
        self.createDataTask(useLongSession, queueItem: queueItem, request: request as URLRequest)
    }
    
    func createDataTask(_ useLongSession: Bool, queueItem: MWTaskItem?, request: URLRequest?) -> Void {
        
        let newSessionDataTask: URLSessionDataTask? = (useLongSession ? self.longSession : self.sendSession).dataTask(with: request!)
        
        queueItem?.addTaksinfo(.in_PROGRESS, _taskID: getTaskIndificator(newSessionDataTask!), _request: request!)
        
        taskItemsQueue[queueItem!.taskIndificator!] = queueItem
        
        MWLog.printLog("Taks created: " as AnyObject?,queueItem)
        
        newSessionDataTask!.resume()
    }
    
    func URLSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
        
        let taskKey = getTaskIndificator(dataTask)
        
        if let taskItem = taskItemsQueue[taskKey] {
            
            if !self.validateResponse(dataTask, taskItem: taskItem) {
                
                taskItem.resetStoredData()
                self.runQueue()
                return
            }
            
            if dataTask.state == URLSessionTask.State.running {
                
                _ = taskItem.appendDataToStoredValue(data)
                
                let result = self.tryToDecodeRecivedData(taskItem.storedTaskData! as Data)
                
                if result != nil {
                    
                    MWLog.printLog("Taks Result: " as AnyObject?,result)
                    
                    taskItemsQueue.removeValue(forKey: taskKey)
                }
                else {
                    taskItemsQueue[taskKey] = taskItem;
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            let taskKey = getTaskIndificator(task as! URLSessionDataTask)
            
            if (task.state == URLSessionTask.State.canceling || task.state ==  URLSessionTask.State.completed) {
                if taskItemsQueue[taskKey] != nil {
                    taskItemsQueue.removeValue(forKey: taskKey)
                }
            }
        }
    }
    
    fileprivate func addBaseSessionParameters(_ config: URLSessionConfiguration) -> Void {
        
        config.httpShouldUsePipelining = true
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Connection":"Upgrade","Content-Encoding":"gzip","Accept":"application/json","Content-Type":"application/json"]
    }
    
    fileprivate var sendSession: Foundation.URLSession!
    fileprivate var longSession: Foundation.URLSession!

    fileprivate func getTaskIndificator(_ _task: URLSessionDataTask) -> String {
        
        let iDx = _task.taskIdentifier
        return "\(iDx)"
    }
    
    fileprivate func tryToDecodeRecivedData(_ data: Data) -> NSDictionary? {
        
        do {
            if let rez = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: AnyObject] {
                return rez as NSDictionary?
            }
        } catch  {
        }
        
        return nil
    }
    
    fileprivate func validateResponse(_ dataTask: URLSessionDataTask, taskItem: MWTaskItem) -> Bool {
        
        let response = dataTask.response as! HTTPURLResponse
        let sCode = response.statusCode
        
        switch sCode {
        case 200:
            return true
        default:
            return false
        }
    }
}
