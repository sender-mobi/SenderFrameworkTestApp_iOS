//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ContactPagePresenter: ContactPagePresenterProtocol {

    weak var view: ContactPageViewProtocol?
    weak var delegate: ContactPageModuleDelegate?
    var router: ContactPageRouterProtocol?
    var interactor: ContactPageInteractorProtocol

    init(interactor: ContactPageInteractorProtocol, router: ContactPageRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.view?.updateWith(viewModel: self.interactor.p2pChat)
    }

    func chatWasUpdated(_ chat: Dialog) {
        self.view?.updateWith(viewModel: chat)
    }

    func goToChatWith(actions: [[String: AnyObject]]?) {
        self.router?.presentChatWith(actions: actions)
    }

    func handleAction(_ action: [AnyHashable: Any]) {
        guard let callRobotModel = CallRobotModel(actionDictionary: action) else { return }
        self.router?.presentRobotScreenWith(callRobotModel: callRobotModel)
    }

    func closeContactPage() {
        self.delegate?.contactPageModuleDidFinish()
    }
}
