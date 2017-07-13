//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatEditorRouter: ChatEditorRouterProtocol {
    weak var presenter: ChatEditorPresenterProtocol?

    private weak var currentChatEditorView: EditChatViewController?
    private var currentWireframe: ViewControllerWireframe?

    var chatEditorView: EditChatViewController {
        if let existingView = self.currentChatEditorView {
            return existingView
        } else {
            let newView = self.buildChatEditorView()
            self.currentChatEditorView = newView
            return newView
        }
    }

    func buildChatEditorView() -> EditChatViewController {
        return EditChatViewController.loadFromSenderFrameworkStoryboardWith(name: "ChatViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatEditorModuleDelegate?)
                    -> EditChatViewController {
        let chatEditorView = self.chatEditorView
        chatEditorView.presenter = self.presenter
        self.presenter?.view = chatEditorView
        self.presenter?.delegate = moduleDelegate
        return chatEditorView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatEditorModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatEditorView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatEditorView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(chatEditorView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let chatEditorView = self.currentChatEditorView else { return }
        self.currentWireframe?.dismissView(chatEditorView, completion: completion)
    }
}
