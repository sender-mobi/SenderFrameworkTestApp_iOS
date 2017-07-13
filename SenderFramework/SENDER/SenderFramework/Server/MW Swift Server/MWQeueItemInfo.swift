//
//  MWQeueItemInfo.swift
//  SENDER
//
//  Created by Eugene Gilko on 6/23/15.
//  Copyright © 2015 MiddleWare. All rights reserved.
//

import Foundation

class MWQueueItem {
    
    var pathUrl: String?
    var complitionHandler: SenderRequestCompletionHandler?
    var postData: NSDictionary?
    
    func initWithParameters(_ _postData: NSDictionary?, _pathUrl: String?, _completion: SenderRequestCompletionHandler?) {
        
        if  _pathUrl != nil {
            pathUrl = _pathUrl!
        }
        
        if _completion != nil {
            complitionHandler = _completion!
        }
        
        if _postData != nil {
            postData = _postData
        }
    }    
}

class MWTaskItem {

    var taskIndificator: String?
    var taskState: QueueItemState?
    var storedTaskData : NSMutableData?
    var postData: NSMutableDictionary?
    var pathUrl: String?
    var storedRequest: URLRequest?
    var storedItems: [String:MWQueueItem]?
    var rid: Int?
    var useLongSession: Bool?
    
    func initWIthURL(_ _pathUrl: String?) {
        
        if  _pathUrl != nil {
            pathUrl = _pathUrl!
        }
        else {
            pathUrl = kSendPath
        }
        
        storedItems = [String:MWQueueItem]()
        storedTaskData = NSMutableData()
        postData = NSMutableDictionary()
    }
    
    func addPostDataFromDictionary(_ postData_: NSDictionary) {
        postData = postData_.mutableCopy() as? NSMutableDictionary
    }
    
    func addNewKVInPostData(_ key: String?, value: AnyObject?) {
        postData![key!] = value!
    }
    
    func assignRidInfo(_ _rid: Int) {
        rid = _rid
    }
    
    func addTaksinfo(_ _taskState: QueueItemState, _taskID: String, _request: URLRequest) {
        storedRequest = _request
        taskState = _taskState
        taskIndificator = _taskID
    }
    
    func resetStoredData() -> Void {
        storedTaskData = NSMutableData()
    }
    
    func appendDataToStoredValue(_ newData:Data) -> Data {
        storedTaskData?.append(newData)
        return storedTaskData as Data!
    }
    
    func addNewItemToTask(_ item:MWQueueItem,cidID:String) {
        storedItems![cidID] = item
    }
}
