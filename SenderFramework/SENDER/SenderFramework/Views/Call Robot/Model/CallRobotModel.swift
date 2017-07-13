//
// Created by Roman Serga on 2/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class CallRobotModel: NSObject, CallRobotModelProtocol {

    public private(set) var robotID: String
    public private(set) var companyID: String
    public var formID: String?
    public var chatID: String?
    public var userID: String?
    public var model: [AnyHashable: Any]?

    public init(robotID: String, companyID: String) {
        self.robotID = robotID
        self.companyID = companyID
        super.init()
    }
}

extension CallRobotModel {
    convenience init?(classString: String) {
        let components = classString.components(separatedBy: ".")
        guard components.count > 2 else { return nil }
        self.init(robotID: components[1], companyID: components[2])
        self.formID = components[0]
    }
}

extension CallRobotModel {
    convenience init?(actionDictionary: [AnyHashable: Any]) {
        guard let classString = actionDictionary["class"] as? String else { return nil }
        self.init(classString: classString)
        if let userID = actionDictionary["userId"] as? String {
            self.chatID = chatIDFromUserID(userID)
            self.userID = userID
        } else {
            self.chatID = actionDictionary["chatId"] as? String
        }
        if let model = actionDictionary["data"] as? [AnyHashable: Any] { self.model = model }
    }
}
