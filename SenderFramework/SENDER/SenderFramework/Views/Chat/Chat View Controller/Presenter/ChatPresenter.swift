//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatPresenter: ChatPresenterProtocol {
    weak var view: ChatViewProtocol?
    weak var delegate: ChatModuleDelegate?
    var router: ChatRouterProtocol?
    var interactor: ChatInteractorProtocol

    init(interactor: ChatInteractorProtocol, router: ChatRouterProtocol?) {
        self.interactor = interactor
        self.router = router
    }

    func callContact() {
        self.router?.showCallScreen()
    }

    func openChatSettings() {
        self.router?.showChatSettings()
    }

    func closeChatSettings() {
        self.router?.dismissChatSettings()
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func viewDidAppear() {
        self.interactor.isActive = true
    }

    func viewDidDisappear() {
        self.interactor.isActive = false
    }

    func chatSettingsModuleDidUpdateChat(_ chat: Dialog) {
        self.interactor.updateWith(chat: chat)
    }

    func chatWasUpdated(_ chat: Dialog) {
        self.view?.updateWith(viewModel: chat)
        self.router?.updateChatSettingsWith(chat: chat)
    }

    func addMembersToChat() {
        self.router?.presentAddMemberScreen()
    }

    func addToChatModuleDidFinishWith(newChat: Dialog, selectedEntities: [EntityViewModel]) {
        self.interactor.updateWith(chat: newChat)
        self.router?.dismissAddMemberScreen()
        self.router?.updateChatSettingsWith(chat: newChat)
    }

    func entityPickerModuleDidCancel() {
        self.router?.dismissAddMemberScreen()
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        self.router?.dismissAddMemberScreen()
    }

    func showQRScanner() {
        self.router?.presentQRScanner()
    }

    func qrScannerModuleDidCancel() {
        self.router?.dismissQRScanner()
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.router?.dismissQRScanner()
        self.interactor.handleScannedQRString(string)
    }

    func handleAction(_ action: [AnyHashable: Any]) {
        guard let callRobotModel = CallRobotModel(actionDictionary: action) else { return }
        self.interactor.callRobot(callRobotModel)
    }

    func closeChat() {
        self.delegate?.chatModuleDidFinish()
    }

    func setChatSettingsEnabled(_ enabled: Bool) {
        self.router?.setChatSettingsDisplayingEnabled(enabled)
    }
}
