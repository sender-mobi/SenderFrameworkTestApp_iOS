//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension ChatEditManager: ChatSettingsDataManagerProtocol {}

@objc public class ChatSettingsModule: NSObject, ChatSettingsModuleProtocol {

    var chatEditorModule: ChatEditorModuleProtocol
    var chatMembersModule: ChatMembersModuleProtocol
    var contactPageModule: ContactPageModuleProtocol
    var addToChatModule: AddToChatModuleProtocol

    private weak var router: ChatSettingsRouterProtocol?

    public init(chatEditorModule: ChatEditorModuleProtocol,
                chatMembersModule: ChatMembersModuleProtocol,
                contactPageModule: ContactPageModuleProtocol,
                addToChatModule: AddToChatModuleProtocol) {
        self.chatEditorModule = chatEditorModule
        self.chatMembersModule = chatMembersModule
        self.contactPageModule = contactPageModule
        self.addToChatModule = addToChatModule
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            chat: Dialog,
                            forDelegate delegate: ChatSettingsModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatSettingsDataManager = ChatEditManager(input: chatEditManagerInput)
        let chatSettingsInteractor = ChatSettingsInteractor(dataManager: chatSettingsDataManager)
        let chatSettingsRouter = ChatSettingsRouter(chatEditorModule: self.chatEditorModule,
                                                    chatMembersModule: self.chatMembersModule,
                                                    contactPageModule: self.contactPageModule,
                                                    addToChatModule: self.addToChatModule)
        let chatSettingsPresenter = ChatSettingsPresenter(interactor: chatSettingsInteractor,
                                                          router: chatSettingsRouter)
        chatSettingsInteractor.presenter = chatSettingsPresenter
        chatSettingsInteractor.updateWith(chat: chat)
        chatSettingsRouter.presenter = chatSettingsPresenter
        chatSettingsRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatSettingsRouter
    }

    public func updateWith(chat: Dialog) {
        self.router?.presenter?.interactor.updateWith(chat: chat)
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }

}
