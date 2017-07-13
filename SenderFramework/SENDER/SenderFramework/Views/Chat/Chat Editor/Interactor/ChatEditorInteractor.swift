//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatEditorInteractor: ChatEditorInteractorProtocol {
    weak var presenter: ChatEditorPresenterProtocol?
    var chat: Dialog!

    var dataManager: ChatEditorDataManagerProtocol

    init(dataManager: ChatEditorDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
        self.presenter?.chatWasUpdated(chat)
    }

    func editChatWith(name: String?, description: String?, imageData: Data?) {
        self.dataManager.edit(chat: self.chat,
                              withName: name,
                              description: description,
                              imageData: imageData) { chat, error in
            guard let newChat = chat, error == nil else { return }
            self.updateWith(chat: newChat)
            self.presenter?.finishEditingChat()
        }
    }
}

extension ChatEditorInteractor: ChatsChangesHandler {
    func handleChatsChange(_ chats: [Dialog]) {
        for chat in chats {
            if chat.chatID == self.chat.chatID { self.updateWith(chat: chat) }
        }
    }
}
