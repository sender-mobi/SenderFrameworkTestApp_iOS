//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension ChatEditManager: ChatMembersDataManagerProtocol {}

@objc public class ChatMembersModule: NSObject, ChatMembersModuleProtocol {

    private weak var router: ChatMembersRouterProtocol?

    var contactPageModule: ContactPageModuleProtocol

    public init(contactPageModule: ContactPageModuleProtocol) {
        self.contactPageModule = contactPageModule
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            chat: Dialog, forDelegate
                            delegate: ChatMembersModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatMembersDataManager = ChatEditManager(input: chatEditManagerInput)
        let chatMembersInteractor = ChatMembersInteractor(dataManager: chatMembersDataManager)
        let chatMembersRouter = ChatMembersRouter(contactPageModule: contactPageModule)
        let chatMembersPresenter = ChatMembersPresenter(interactor: chatMembersInteractor, router: chatMembersRouter)
        chatMembersInteractor.updateWith(chat: chat)
        chatMembersInteractor.presenter = chatMembersPresenter
        chatMembersRouter.presenter = chatMembersPresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(chatMembersInteractor)
        chatMembersRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatMembersRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }

}
