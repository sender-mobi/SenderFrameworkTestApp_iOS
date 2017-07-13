//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsInteractor: ChatSettingsInteractorProtocol {
    var chat: Dialog!
    weak var presenter: ChatSettingsPresenterProtocol?
    var dataManager: ChatSettingsDataManagerProtocol

    init(dataManager: ChatSettingsDataManagerProtocol) {
        self.dataManager = dataManager
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(self)
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
        self.presenter?.chatWasUpdated(self.chat)
    }

    func addMembers(_ members: [Dialog]) {
        self.dataManager.add(members: members,
                             toChat: self.chat,
                             completionHandler: self.refreshPresenterWith)
    }

    private func refreshPresenterWith(chat: Dialog?, error: Error?) {
        guard let newChat = chat, error == nil else { return }
        self.updateWith(chat: newChat)
    }

    func leaveChat() {
       self.dataManager.leave(chat: self.chat, completionHandler: self.refreshPresenterWith)
    }

    func changeEncryptionStateTo(_ newEncryptionState: Bool) {
        self.dataManager.setEncryptionStateOf(chat: self.chat,
                                              encryptionState: newEncryptionState,
                                              completionHandler: self.refreshPresenterWith)
    }

    func changeFavoriteStateTo(_ newFavoriteState: Bool) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.isFavorite = newFavoriteState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeBlockStateTo(_ newBlockState: Bool) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.isBlocked = newBlockState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.soundScheme = newSoundScheme
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.muteChatNotification = newMuteState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hidePushNotification = newHidePushState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.smartPushNotification = newSmartPushState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hideTextNotification = newHideTextState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hideCounterNotification = newHideCounterState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    private func updateChat(_ chat: Dialog, withSettings settings: ChatSettingsEditModel) {
        self.dataManager.changeSettingsOf(chat: chat,
                                          newSettings: settings,
                                          completionHandler: self.refreshPresenterWith)
    }
}

extension ChatSettingsInteractor: ChatsChangesHandler {
    func handleChatsChange(_ chats: [Dialog]) {
        for chat in chats {
            if chat.chatID == self.chat.chatID { self.updateWith(chat: chat) }
        }
    }
}

extension ChatSettingsInteractor: OnlineStatusChangesHandler {
    func handleOnlineStatusChangeForContacts(_ contacts: [Contact]) {
        guard self.chat.isP2P, let p2pContact = self.chat.p2pContact else { return }
        for contact in contacts {
            if contact.userID == p2pContact.userID { self.updateWith(chat: self.chat) }
        }
    }
}