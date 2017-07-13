//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatListModule: NSObject, ChatListModuleProtocol {

    fileprivate weak var router: ChildChatListRouter?

    public var addContactModule: AddContactModuleProtocol
    public var qrScannerModule: QRScannerModuleProtocol
    public var senderUI: SenderUIProtocol {
        didSet {
            self.router?.senderUI = self.senderUI
        }
    }

    public init(addContactModule: AddContactModuleProtocol,
                qrScannerModule: QRScannerModuleProtocol,
                senderUI: SenderUIProtocol) {
        self.addContactModule = addContactModule
        self.qrScannerModule = qrScannerModule
        self.senderUI = senderUI
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            forDelegate delegate: ChatListModuleDelegate?,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let chatListRouter = ChildChatListRouter(addContactModule: self.addContactModule,
                                                 qrScannerModule: self.qrScannerModule,
                                                 senderUI: self.senderUI)
        let chatListPresenter = ChatListPresenter(router: chatListRouter)
        chatListRouter.presenter = chatListPresenter
        chatListRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatListRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }
}

public class ChildChatListModule: ChatListModule, ChildChatListModuleProtocol {

    public func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                              forDelegate delegate: ChatListModuleDelegate?,
                                                              completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let chatListRouter = ChildChatListRouter(addContactModule: self.addContactModule,
                                                 qrScannerModule: self.qrScannerModule,
                                                 senderUI: self.senderUI)
        let chatListPresenter = ChatListPresenter(router: chatListRouter)
        chatListRouter.presenter = chatListPresenter
        chatListRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatListRouter
    }

}
