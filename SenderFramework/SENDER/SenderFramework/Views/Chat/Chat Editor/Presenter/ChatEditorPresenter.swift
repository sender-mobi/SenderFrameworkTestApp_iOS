//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatEditorPresenter: ChatEditorPresenterProtocol {

    weak var view: ChatEditorViewProtocol?
    weak var delegate: ChatEditorModuleDelegate?
    var router: ChatEditorRouterProtocol?
    var interactor: ChatEditorInteractorProtocol

    var newName: String?
    var newDescription: String?
    var newImageData: Data?

    init(interactor: ChatEditorInteractorProtocol, router: ChatEditorRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.view?.updateWith(viewModel: self.interactor.chat)
    }

    func chatWasUpdated(_ chat: Dialog) {
        self.view?.updateWith(viewModel: chat)
    }

    func editChat() {
        self.interactor.editChatWith(name: newName,
                                     description: newDescription,
                                     imageData: newImageData)
    }

    func finishEditingChat() {
        self.delegate?.chatEditorPresenterDidFinish()
    }

    func cancelEditingChat() {
        self.delegate?.chatEditorPresenterDidCancel()
    }

    func handleError(_ error: Error) {
    }
}
