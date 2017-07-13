//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatInteractor: ChatInteractorProtocol {

    var chat: Dialog!
    var chatID: String!
    var isActive: Bool = false

    weak var presenter: ChatPresenterProtocol?

    var dataManager: ChatDataManagerProtocol

    init(dataManager: ChatDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        self.presenter?.chatWasUpdated(self.chat)
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
        self.chatID = chat.chatID
        self.presenter?.chatWasUpdated(self.chat)
    }

    func updateWith(chatID: String) {
        self.chatID = chatID
        let chat = self.dataManager.chatWith(chatID: self.chatID)
        self.updateWith(chat: chat)
    }

    func callRobot(_ callRobotModel: CallRobotModel) {
        if let robotChatID = callRobotModel.chatID {
            if robotChatID != self.chatID { self.updateWith(chatID: robotChatID) }
        } else {
            callRobotModel.chatID = self.chatID
        }
        self.dataManager.callRobotWith(model: callRobotModel, completion: nil)
    }

    func handleScannedQRString(_ qrString: String) {
        self.dataManager.sendQRString(qrString, chatID: self.chatID, completion: nil)
    }
}
