//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatRouter: ChatRouterProtocol {

    weak var presenter: ChatPresenterProtocol?

    var addToChatModule: AddToChatModuleProtocol
    var qrScannerModule: QRScannerModuleProtocol
    var chatSettingsModule: ChatSettingsModuleProtocol
    init(chatSettingsModule: ChatSettingsModuleProtocol,
         addToChatModule: AddToChatModuleProtocol,
         qrScannerModule: QRScannerModuleProtocol) {
        self.chatSettingsModule = chatSettingsModule
        self.addToChatModule = addToChatModule
        self.qrScannerModule = qrScannerModule
    }

    var dragWireframe: DragFromRightWireframe?
    var isSettingsScreenAdded: Bool { return dragWireframe != nil }
    private weak var currentChatView: ChatViewController?
    private var currentWireframe: ViewControllerWireframe?

    var chatView: ChatViewController {
        if let existingView = self.currentChatView {
            return existingView
        } else {
            let newView = self.buildChatView()
            self.currentChatView = newView
            return newView
        }
    }

    func buildChatView() -> ChatViewController {
        return ChatViewController.loadFromSenderFrameworkStoryboardWith(name: "ChatViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatModuleDelegate?,
                                                          model: ChatPresentationModelProtocol)
                    -> ChatViewController {
        let chatView = self.chatView
        chatView.presenter = self.presenter
        chatView.customBackgroundImage = model.options?[ChatPresentationModelOption.customBackgroundImage] as? UIImage
        chatView.customBackgroundImageURL = model.options?[ChatPresentationModelOption.customBackgroundImageURL] as? URL
        chatView.hidesSendBar = (model.options?[ChatPresentationModelOption.hideSendBar] as? Bool) ?? false
        chatView.sendBarActions = model.actions

        self.presenter?.view = chatView
        self.presenter?.delegate = moduleDelegate
        return chatView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         model: ChatPresentationModelProtocol,
                         forDelegate delegate: ChatModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate, model: model)
        wireframe.presentView(chatView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentChatView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.chatSettingsModule.dismissWithChildModules(completion: nil)
        self.dismissAddMemberScreen()
        self.dismissQRScanner()
        self.dismissView(completion: completion)
    }

    func addChatSettingsWith(chat: Dialog) {
        self.dragWireframe = DragFromRightWireframe(rootView: chatView)
        self.chatSettingsModule.presentWith(wireframe: self.dragWireframe!,
                                            chat: chat,
                                            forDelegate: self.presenter,
                                            completion: nil)
        self.dragWireframe?.delegate = chatView
    }

    func showChatSettings() {
        self.dragWireframe?.showCurrentView()
    }

    func dismissChatSettings() {
        self.dragWireframe?.hideCurrentView()
    }

    func setChatSettingsDisplayingEnabled(_ enabled: Bool) {
        self.dragWireframe?.isGestureRecognizerEnabled = enabled
    }

    func updateChatSettingsWith(chat: Dialog) {
        if !self.isSettingsScreenAdded { self.addChatSettingsWith(chat: chat) }
        self.chatSettingsModule.updateWith(chat: chat)
    }

    func showCallScreen() {
    }

    func presentAddMemberScreen() {
        guard let currentChatView = currentChatView, let chat = self.presenter?.interactor.chat else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        self.addToChatModule.presentWith(wireframe: wireframe,
                                         chat: chat,
                                         allowsMultipleSelection: true,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissAddMemberScreen() {
        self.addToChatModule.dismiss(completion: nil)
    }

    func presentQRScanner() {
        guard let currentChatView = currentChatView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        wireframe.animatedPresentation = true
        self.qrScannerModule.presentWith(wireframe: wireframe,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissQRScanner() {
        self.qrScannerModule.dismiss(completion: nil)
    }

}
