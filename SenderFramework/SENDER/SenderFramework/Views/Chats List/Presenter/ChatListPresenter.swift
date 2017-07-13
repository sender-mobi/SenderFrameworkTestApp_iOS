//
// Created by Roman Serga on 18/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatListPresenter: ChatListPresenterProtocol {

    weak var view: ChatListViewProtocol?
    weak var delegate: ChatListModuleDelegate?
    var router: ChatListRouterProtocol?

    init(router: ChatListRouterProtocol) {
        self.router = router
    }

    func performMainAction() {
        self.delegate?.chatListDidPerformedMainAction()
    }

    func startAddingContact() {
        self.router?.showAddContactForm()
    }

    func addContactPresenterDidCancel() {
        self.router?.dismissAddContactForm()
    }

    func addContactPresenterDidFinish() {
        self.router?.dismissAddContactForm()
    }

    func showQRScanner() {
        self.router?.presentQRScanner()
    }

    func qrScannerModuleDidCancel() {
        self.router?.dismissQRScanner()
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.router?.dismissQRScanner()
    }

    func showChatWith(chatID: String, actions: [[String: AnyObject]]?) {
        self.router?.presentChatWith(chatID: chatID, actions: actions)
    }

    func showChatWith(chat: Dialog, actions: [[String: AnyObject]]?) {
        self.router?.presentChatWith(chat: chat, actions: actions)
    }

    func launchAction(_ action: ActionCellModel) {
        guard let classString = action.cellClass,
              let callRobotModel = CallRobotModel(classString: classString) else { return }
        if let userID = action.cellUserID { callRobotModel.chatID = chatIDFromUserID(userID) }
        if let model = action.cellActionData { callRobotModel.model = model }
        self.router?.presentRobotScreenWith(callRobotModel: callRobotModel)
    }
}
