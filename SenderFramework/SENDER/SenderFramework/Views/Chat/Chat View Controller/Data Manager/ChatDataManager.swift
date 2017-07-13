//
// Created by Roman Serga on 2/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatDataManager: ChatEditManager, ChatDataManagerProtocol {

    public func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        var postData = [AnyHashable: Any]()
        postData["formId"] = model.formID ?? ""
        postData["robotId"] = model.robotID
        postData["companyId"] = model.companyID
        if let userID = model.userID {
            postData["userId"] = userID
        }

        let senderChatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
        ServerFacade.sharedInstance().callRobot(withParameters: postData,
                                                chatID: model.chatID ?? senderChatID,
                                                withModel: model.model,
                                                requestHandler: completion)
    }

    public func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendQR(qrString,
                                             chatID: chatID,
                                             additionalParameters: nil) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }

}
