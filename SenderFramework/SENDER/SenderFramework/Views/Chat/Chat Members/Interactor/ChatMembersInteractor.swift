//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatMembersInteractor: ChatMembersInteractorProtocol {
    weak var presenter: ChatMembersPresenterProtocol?
    fileprivate(set) var chat: Dialog!
    var dataManager: ChatMembersDataManagerProtocol

    init(dataManager: ChatMembersDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func deleteMember(_ member: ChatMember) {
        self.dataManager.deleteMembers([member], ofChat: self.chat) { chat, error in
            guard let newChat = chat, error == nil else { return }
            self.updateWith(chat: newChat)
        }
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
        self.presenter?.chatWasUpdated(self.chat)
    }
}

extension ChatMembersInteractor: ChatsChangesHandler {
    func handleChatsChange(_ chats: [Dialog]) {
        for chat in chats {
            if chat.chatID == self.chat.chatID { self.updateWith(chat: chat) }
        }
    }
}
