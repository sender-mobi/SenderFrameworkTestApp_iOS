//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsPresenter: ChatSettingsPresenterProtocol {

    weak var view: ChatSettingsViewProtocol?
    weak var delegate: ChatSettingsModuleDelegate?
    var router: ChatSettingsRouterProtocol?
    var interactor: ChatSettingsInteractorProtocol

    init(interactor: ChatSettingsInteractorProtocol, router: ChatSettingsRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.view?.updateWith(viewModel: self.interactor.chat)
    }

    func editChat() {
        self.router?.presentChatEditScreen()
    }

    func showChatMembers() {
        self.router?.presentMembersScreen()
    }

    func chatWasUpdated(_ chat: Dialog) {
        self.view?.updateWith(viewModel: chat)
    }

    func leaveChat() {
        self.interactor.leaveChat()
    }

    func addParticipants() {
        self.router?.presentAddMemberScreen()
    }

    func showContactPage() {
        self.router?.presentContactPage()
    }

    func changeEncryptionStateTo(_ newEncryptionState: Bool) {
        self.interactor.changeEncryptionStateTo(newEncryptionState)
    }

    func changeFavoriteStateTo(_ newFavoriteState: Bool) {
        self.interactor.changeFavoriteStateTo(newFavoriteState)
    }

    func changeBlockStateTo(_ newBlockState: Bool) {
        self.interactor.changeBlockStateTo(newBlockState)
    }

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme) {
        self.interactor.changeSoundSchemeTo(newSoundScheme)
    }

    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType) {
        self.interactor.changeMuteChatStateTo(newMuteState)
    }

    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType) {
        self.interactor.changeHidePushStateTo(newHidePushState)
    }

    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType) {
        self.interactor.changeSmartPushStateTo(newSmartPushState)
    }

    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType) {
        self.interactor.changeHideTextStateTo(newHideTextState)
    }

    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType) {
        self.interactor.changeHideCounterStateTo(newHideCounterState)
    }

    func chatEditorPresenterDidCancel() {
        self.router?.dismissChatEditScreen()
    }

    func chatEditorPresenterDidFinish() {
        self.router?.dismissChatEditScreen()
    }

    func entityPickerModuleDidCancel() {
        self.router?.dismissAddMemberScreen()
    }

    func addToChatModuleDidFinishWith(newChat: Dialog, selectedEntities: [EntityViewModel]) {
        self.router?.dismissAddMemberScreen()
        self.interactor.updateWith(chat: newChat)
        self.delegate?.chatSettingsModuleDidUpdateChat(newChat)
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        self.router?.dismissAddMemberScreen()
    }

    func contactPageModuleDidFinish() {

    }
}
