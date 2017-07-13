//
//  MWServerFacade.swift
//  SENDER
//
//  Created by Eugene Gilko on 1/29/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

//typealias MWCommonCompletionHandler = (response : [String : AnyObject]?, error : NSError?) -> Void

class MWServerFacade : NSObject {
    
    static let shared = MWServerFacade()
    
    let cometController :  MWCometController? = MWCometController()
    let sendController : MWSendController? = MWSendController()
    
    func runTestSend() -> Void {
        sendController?.runSendQueue()
    }
}
