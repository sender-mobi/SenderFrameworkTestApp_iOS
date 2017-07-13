//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ContactPageModule: NSObject, ContactPageModuleProtocol {

    private weak var router: ContactPageRouterProtocol?

    public var senderUI: SenderUIProtocol {
        didSet {
            if let humanRouter = self.router as? HumanContactPageRouter {
                humanRouter.senderUI = self.senderUI
            } else if let companyRouter = self.router as? CompanyContactPageRouter {
                companyRouter.senderUI = self.senderUI
            }
        }
    }

    public init(senderUI: SenderUIProtocol) {
        self.senderUI = senderUI
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            p2pChat: Dialog,
                            forDelegate delegate: ContactPageModuleDelegate?,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presenter?.interactor.updateWith(p2pChat: p2pChat)
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let contactPageInteractor = ContactPageInteractor()
        let contactPageRouter: ContactPageRouterProtocol
        if p2pChat.chatType == .company {
            contactPageRouter = CompanyContactPageRouter(senderUI: senderUI)
        } else {
            contactPageRouter = HumanContactPageRouter(senderUI: senderUI)
        }
        let contactPagePresenter = ContactPagePresenter(interactor: contactPageInteractor, router: contactPageRouter)
        contactPageInteractor.updateWith(p2pChat: p2pChat)
        contactPageInteractor.presenter = contactPagePresenter
        contactPageRouter.presenter = contactPagePresenter
        contactPageRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = contactPageRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
