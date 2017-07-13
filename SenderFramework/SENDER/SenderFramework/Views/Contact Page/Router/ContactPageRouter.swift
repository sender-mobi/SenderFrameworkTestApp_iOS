//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class ContactPageRouter<ViewControllerType>: ContactPageRouterProtocol
        where ViewControllerType: ContactPageViewProtocol,
        ViewControllerType: UIViewController {

    weak var presenter: ContactPagePresenterProtocol?

    private weak var currentContactView: ViewControllerType?
    private var currentWireframe: ViewControllerWireframe?

    var senderUI: SenderUIProtocol

    init(senderUI: SenderUIProtocol) {
        self.senderUI = senderUI
    }

    var contactView: ViewControllerType {
        if let existingView = self.currentContactView {
            return existingView
        } else {
            let newView = self.buildContactView()
            self.currentContactView = newView
            return newView
        }
    }

    func buildContactView() -> ViewControllerType {
        fatalError("Method createContactView() must be overriden by subclasses of ContactPageRouter")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ContactPageModuleDelegate?)
                    -> ViewControllerType {
        let contactView = self.contactView
        contactView.presenter = self.presenter
        self.presenter?.view = contactView
        self.presenter?.delegate = moduleDelegate
        return contactView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ContactPageModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentContactView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let contactView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(contactView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentContactView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func presentChatWith(actions: [[String: AnyObject]]?) {
        guard let chat = self.presenter?.interactor.p2pChat else { return }
        _ = self.senderUI.showChatScreenWith(chat: chat,
                                             actions: actions,
                                             options: nil,
                                             animated: true,
                                             modally: false,
                                             delegate: nil)
    }

    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol) {
        _ = self.senderUI.showRobotScreenWith(model: callRobotModel, animated: true, modally: false, delegate: nil)
    }
}
