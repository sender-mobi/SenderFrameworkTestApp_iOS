//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension ChatEditManager: ChatEditorDataManagerProtocol {}

@objc public class ChatEditorModule: NSObject, ChatEditorModuleProtocol {

    private weak var router: ChatEditorRouterProtocol?

    public func presentWith(wireframe: ViewControllerWireframe,
                            chat: Dialog,
                            forDelegate delegate: ChatEditorModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatEditorDataManager = ChatEditManager(input: chatEditManagerInput)
        let chatEditorInteractor = ChatEditorInteractor(dataManager: chatEditorDataManager)
        let chatEditorRouter = ChatEditorRouter()
        let chatEditorPresenter = ChatEditorPresenter(interactor: chatEditorInteractor, router: chatEditorRouter)
        chatEditorInteractor.chat = chat
        chatEditorInteractor.presenter = chatEditorPresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(chatEditorInteractor)
        chatEditorRouter.presenter = chatEditorPresenter
        chatEditorRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatEditorRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

}