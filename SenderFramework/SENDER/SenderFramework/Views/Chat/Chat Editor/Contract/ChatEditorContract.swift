//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ChatEditorViewProtocol: class {
    var presenter: ChatEditorPresenterProtocol? { get set }
    func showInvalidDataError()
    func updateWith(viewModel: Dialog)
}

@objc public protocol ChatEditorModuleDelegate: class {
    func chatEditorPresenterDidCancel()
    func chatEditorPresenterDidFinish()
}

@objc public protocol ChatEditorPresenterProtocol: class {
    weak var view: ChatEditorViewProtocol? { get set }
    weak var delegate: ChatEditorModuleDelegate? { get set }
    var router: ChatEditorRouterProtocol? { get set }
    var interactor: ChatEditorInteractorProtocol { get set }

    var newName: String? { get set }
    var newDescription: String? { get set }
    var newImageData: Data? { get set }

    func viewWasLoaded()
    func chatWasUpdated(_ chat: Dialog)

    func editChat()
    func finishEditingChat()
    func cancelEditingChat()
    func handleError(_ error: Error)
}

@objc public protocol ChatEditorRouterProtocol: class {
    weak var presenter: ChatEditorPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatEditorModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc public protocol ChatEditorInteractorProtocol: class {
    weak var presenter: ChatEditorPresenterProtocol? { get set }
    var chat: Dialog! { get }

    func updateWith(chat: Dialog)
    func editChatWith(name: String?, description: String?, imageData: Data?)
}

protocol ChatEditorDataManagerProtocol {
    func edit(chat: Dialog,
              withName name: String?,
              description: String?,
              imageData: Data?,
              completionHandler: ((Dialog?, Error?) -> Void)?)
}

@objc public protocol ChatEditorModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     chat: Dialog,
                     forDelegate delegate: ChatEditorModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}
