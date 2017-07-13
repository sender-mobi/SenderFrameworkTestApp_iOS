//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsRouter: ChatSettingsRouterProtocol {

    weak var presenter: ChatSettingsPresenterProtocol?

    var chatEditorModule: ChatEditorModuleProtocol
    var chatMembersModule: ChatMembersModuleProtocol
    var contactPageModule: ContactPageModuleProtocol
    var addToChatModule: AddToChatModuleProtocol

    private weak var currentChatSettingsView: ChatSettingsViewController?
    private var currentWireframe: ViewControllerWireframe?

    init(chatEditorModule: ChatEditorModuleProtocol,
         chatMembersModule: ChatMembersModuleProtocol,
         contactPageModule: ContactPageModuleProtocol,
         addToChatModule: AddToChatModuleProtocol) {
        self.chatEditorModule = chatEditorModule
        self.chatMembersModule = chatMembersModule
        self.contactPageModule = contactPageModule
        self.addToChatModule = addToChatModule
    }

    var chatSettingsView: ChatSettingsViewController {
        if let existingView = self.currentChatSettingsView {
            return existingView
        } else {
            let newView = self.buildChatSettingsView()
            self.currentChatSettingsView = newView
            return newView
        }
    }

    func buildChatSettingsView() -> ChatSettingsViewController {
        return ChatSettingsViewController.loadFromSenderFrameworkStoryboardWith(name: "ChatViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatSettingsModuleDelegate?)
                    -> ChatSettingsViewController {
        let chatSettingsView = self.chatSettingsView
        chatSettingsView.presenter = self.presenter
        self.presenter?.view = chatSettingsView
        self.presenter?.delegate = moduleDelegate
        return chatSettingsView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatSettingsModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatSettingsView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatSettingsView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(chatSettingsView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentChatSettingsView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.chatEditorModule.dismiss(completion: nil)
        self.chatMembersModule.dismissWithChildModules(completion: nil)
        self.contactPageModule.dismiss(completion: nil)
        self.addToChatModule.dismiss(completion: nil)
        self.dismissView(completion: completion)
    }

    func presentChatEditScreen() {
        guard let settingsView = currentChatSettingsView, let chat = self.presenter?.interactor.chat else { return }
        let wireframe = ModalInNavigationWireframe(rootView: settingsView)
        chatEditorModule.presentWith(wireframe: wireframe,
                                     chat: chat,
                                     forDelegate: self.presenter,
                                     completion: nil)
    }

    func dismissChatEditScreen() {
        self.chatEditorModule.dismiss(completion: nil)
    }

    func presentMembersScreen() {
        guard let navigationController = self.currentChatSettingsView?.navigationController,
              let chat = self.presenter?.interactor.chat else { return }
        let wireframe = PushToNavigationWireframe(rootView: navigationController)
        self.chatMembersModule.presentWith(wireframe: wireframe,
                                           chat: chat,
                                           forDelegate: self.presenter,
                                           completion: nil)
    }

    func presentAddMemberScreen() {
        guard let currentSettingsView = currentChatSettingsView,
              let chat = self.presenter?.interactor.chat else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentSettingsView)
        self.addToChatModule.presentWith(wireframe: wireframe,
                                         chat: chat,
                                         allowsMultipleSelection: true,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissAddMemberScreen() {
        self.addToChatModule.dismiss(completion: nil)
    }

    func presentContactPage() {
        guard let navigationController = self.currentChatSettingsView?.navigationController,
              let chat = self.presenter?.interactor.chat else { return }
        let wireframe = PushToNavigationWireframe(rootView: navigationController)
        self.contactPageModule.presentWith(wireframe: wireframe,
                                           p2pChat: chat,
                                           forDelegate: self.presenter,
                                           completion: nil)
    }
}
