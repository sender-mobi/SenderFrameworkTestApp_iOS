//
//  MWSendController.swift
//  SENDER
//
//  Created by Eugene Gilko on 1/29/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

class MWSendController: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    var sendQueueArray = [MWQueueItem]()
    var simpleQueueArray = [MWQueueItem]()
    var taskItemsQueue = [String:MWTaskItem]()
    
    func addBaseSessionParameters(_ config: URLSessionConfiguration) -> Void {
        
        config.httpShouldUsePipelining = true
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Connection":"Upgrade","Content-Encoding":"gzip","Accept":"application/json","Content-Type":"application/json"]
    }

    override init() {

        super.init()

        let longSessionConfig = URLSessionConfiguration.default
        longSessionConfig.timeoutIntervalForRequest = 120
        self.addBaseSessionParameters(longSessionConfig)
        self.longSession = Foundation.URLSession(configuration: longSessionConfig, delegate: self, delegateQueue:OperationQueue.main)

        let sendSessionConfig = URLSessionConfiguration.default
        sendSessionConfig.timeoutIntervalForRequest = 20
        self.addBaseSessionParameters(sendSessionConfig)
        self.sendSession = Foundation.URLSession(configuration: sendSessionConfig, delegate: self, delegateQueue:OperationQueue.main)
    }

    fileprivate var sendSession: Foundation.URLSession!
    fileprivate var longSession: Foundation.URLSession!

    func addQueueRequest(_ pathUrl: String?, postData: NSDictionary?, completionHolder: SenderRequestCompletionHandler?) -> Void {
        
        if pathUrl != nil {
            self.addSimpleRequestToQueue(pathUrl!, postData: postData, completionHolder: completionHolder)
        }
        else {
            self.addSendRequestToQueue(postData, completionHolder: completionHolder)
        }
    }
    
    func addSendRequestToQueue(_ postData: NSDictionary?, completionHolder: SenderRequestCompletionHandler?) -> Void {
        
        let newSendItem = MWQueueItem()
        newSendItem.initWithParameters(postData!, _pathUrl: "send", _completion: completionHolder)
        sendQueueArray.append(newSendItem)
        self.sendQueueEngine()
    }
    
    func addSimpleRequestToQueue(_ pathUrl: String?, postData: NSDictionary?, completionHolder: SenderRequestCompletionHandler?) -> Void {
        
        let newSimpleItem = MWQueueItem()
        newSimpleItem.initWithParameters(postData!, _pathUrl: pathUrl!, _completion: completionHolder)
//        simpleQueueArray.append(newSimpleItem)
        sendQueueArray.append(newSimpleItem)
        self.sendQueueEngine()
    }
    
//    func simpleQueueEngine() {
//        
//        if sendQueue.count == 0 {
//            while simpleQueue.count > 0 {
//                self.createDataTask(sendSession, queueItem: simpleQueue[0])
//                simpleQueue.removeFirst()
//            }
//        }
//    }
    
    func sendQueueEngine() {
        
        objc_sync_enter(sendQueueArray)
        
            if sendQueueArray.count > 0  {
                
                self.createDataTask(sendSession, queueItem: self.prepareSendQueueForRequest(&sendQueueArray))
            }
        
        objc_sync_exit(sendQueueArray)
    }
    
    func prepareSendQueueForRequest(_ queueArray: inout [MWQueueItem]) -> MWTaskItem! {
        
        let taskItem = MWTaskItem()
        taskItem.initWIthURL("send")
        var fsArray = [NSDictionary]()
        
        if queueArray.count > 1 {
            
            var i = 5
            
            while  i > 0 {
                
                if queueArray.count > 0 {
                  
                    if let qItem: MWQueueItem = queueArray[0] {
                    
                        let cDict = qItem.postData!.mutableCopy() as? NSMutableDictionary
                        cDict!["cid"] = self.getCurrentCID()
                        taskItem.addNewItemToTask(qItem,cidID: cDict!["cid"] as! String)
                        fsArray.append(cDict!)
                        queueArray.removeFirst()
                    }
                }
                
                i -= 1
            }
        }
        else {
            
            if let qItem: MWQueueItem = queueArray[0] {
                
                let cDict = qItem.postData!.mutableCopy() as? NSMutableDictionary
                cDict!["cid"] = self.getCurrentCID()
                taskItem.addNewItemToTask(qItem,cidID: cDict!["cid"] as! String)
                fsArray.append(cDict!)
                queueArray.removeFirst()
            }
        }
        taskItem.addPostDataFromDictionary(["fs":fsArray])
        
        return taskItem
    }
    
    func testRq(_ complitionHandler: SenderRequestCompletionHandler?) {
        
        var postData = [String:AnyObject]()
        postData["chatId"] = CoreDataFacade.sharedInstance().getOwner().senderChatId as AnyObject?
        postData["formId"] = "text" as AnyObject?
        postData["robotId"] = "routerobot" as AnyObject?
        postData["companyId"] = "sender" as AnyObject?
        postData["model"] = ["encrypted":false, "text":"Just a test text"] as AnyObject
        
        self.addSendRequestToQueue(postData as NSDictionary?, completionHolder: complitionHandler)
    }
    
    func runSendQueue() {
        
        testRq({(response, error) -> Void in
            
            let pricesDict = response as? [String : AnyObject]
            
            MWLog.printLog("RESULT : " as AnyObject?, pricesDict as AnyObject?)
            
        })
    }
    
    fileprivate func createDataTask(_ session: Foundation.URLSession?, queueItem: MWTaskItem?) {
        
//        let request = RequestBuilder.shared.buildPOSTRequest(queueItem!.pathUrl!, urlExtraParams: RequestBuilder.shared.getExtraULRParams(), data: queueItem!.postData!)

        let request = SenderRequestBuilder.sharedInstance().request(withPath: queueItem!.pathUrl!, urlParams:SenderRequestBuilder.sharedInstance().urlStringParams(), postData: queueItem!.postData!) as URLRequest
        
        let newSessionDataTask: URLSessionDataTask? = session!.dataTask(with: request)
        
        queueItem?.addTaksinfo(.in_PROGRESS, _taskID: getTaskIndificator(newSessionDataTask!), _request: request)
        
        taskItemsQueue[queueItem!.taskIndificator!] = queueItem
        
        MWLog.printLog("Taks created: " as? AnyObject,queueItem)
        
        newSessionDataTask!.resume()
    }
   
    func URLSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {

        let taskKey = getTaskIndificator(dataTask)
        let taskItem = taskItemsQueue[taskKey]
        
        if (taskItem != nil) {
        
            if dataTask.state == URLSessionTask.State.running {
            
                taskItem!.appendDataToStoredValue(data)
                
                let result = self.tryToDecodeRecivedData(taskItem!.storedTaskData! as Data)
                
                if result.count > 0 {
                
                    let resCode = result["code"]
                    
                    switch resCode! as! Int {
                    case 0:
                        if result["cr"] != nil {
                            for crPart: NSDictionary in result["cr"] as! Array {
                                
                                if let cidId = crPart["cid"] {
                                    let qIt: MWQueueItem = taskItem!.storedItems![cidId as! String]!
                                    qIt.complitionHandler!(crPart as! [AnyHashable: Any], nil)
                                }
                            }
                        }
                        taskItemsQueue.removeValue(forKey: taskKey)
                        break
                    case 1:
                        let delayTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            taskItem!.storedTaskData = NSMutableData()
                             self.createDataTask(self.sendSession, queueItem:taskItem!)
                        }
                        
                        break
                    default:
                        break
                    }
                }
                else {
                    taskItemsQueue[taskKey] = taskItem!;
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            let taskKey = getTaskIndificator(task as! URLSessionDataTask)
            
            if (task.state == URLSessionTask.State.canceling || task.state ==  URLSessionTask.State.completed) {
                taskItemsQueue.removeValue(forKey: taskKey)
            }
            
        } else {
           
        }
    }
    
    fileprivate func getTaskIndificator(_ _task: URLSessionDataTask) -> String {
        
        let tInt = _task.taskIdentifier
        return "\(tInt)"
    }
    
    fileprivate func tryToDecodeRecivedData(_ data: Data) -> NSDictionary {
        
        do {
            if let rez = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: AnyObject] {
               return rez as NSDictionary
            }
        } catch  {
        }
        
        return NSDictionary()
    }
    
    fileprivate func getCurrentCID() -> String {
        let date = Date()
        return String(Int64(date.timeIntervalSince1970 * 1000))
    }
}
