//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatMembersRouter: ChatMembersRouterProtocol {

    weak var presenter: ChatMembersPresenterProtocol?

    var contactPageModule: ContactPageModuleProtocol

    private weak var currentChatMembersView: DialogMembersViewController?
    private var currentWireframe: ViewControllerWireframe?

    init(contactPageModule: ContactPageModuleProtocol) {
        self.contactPageModule = contactPageModule
    }

    var chatMembersView: DialogMembersViewController {
        if let existingView = self.currentChatMembersView {
            return existingView
        } else {
            let newView = self.buildChatMembersView()
            self.currentChatMembersView = newView
            return newView
        }
    }

    func buildChatMembersView() -> DialogMembersViewController {
        return DialogMembersViewController.loadFromSenderFrameworkStoryboardWith(name: "ChatViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatMembersModuleDelegate?)
                    -> DialogMembersViewController {
        let chatMembersView = self.chatMembersView
        chatMembersView.presenter = self.presenter
        self.presenter?.view = chatMembersView
        self.presenter?.delegate = moduleDelegate
        return chatMembersView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatMembersModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatMembersView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let membersView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(membersView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let membersView = self.currentChatMembersView else { return }
        self.currentWireframe?.dismissView(membersView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        contactPageModule.dismiss(completion: nil)
        self.dismissView(completion: completion)
    }

    func presentContactPageViewWith(p2pChat: Dialog) {
        guard let navigationController = self.currentChatMembersView?.navigationController else { return }
        let wireframe = PushToNavigationWireframe(rootView: navigationController)
        self.contactPageModule.presentWith(wireframe: wireframe,
                                           p2pChat: p2pChat,
                                           forDelegate: self.presenter,
                                           completion: nil)
    }
}
