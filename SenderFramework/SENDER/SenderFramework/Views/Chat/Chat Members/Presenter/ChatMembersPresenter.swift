//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatMembersPresenter: ChatMembersPresenterProtocol {
    weak var view: ChatMembersViewProtocol?
    weak var delegate: ChatMembersModuleDelegate?
    var router: ChatMembersRouterProtocol?
    var interactor: ChatMembersInteractorProtocol

    init(interactor: ChatMembersInteractorProtocol, router: ChatMembersRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.view?.updateWith(viewModel: self.interactor.chat)
    }

    func chatWasUpdated(_ chat: Dialog) {
        self.view?.updateWith(viewModel: chat)
    }

    func deleteMember(_ member: ChatMember) {
        self.interactor.deleteMember(member)
    }

    func handleError(_ error: Error) {
    }

    func showContactPageWith(p2pChat: Dialog) {
        self.router?.presentContactPageViewWith(p2pChat: p2pChat)
    }

    func contactPageModuleDidFinish() {
    }
}
