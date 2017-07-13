//
// Created by Roman Serga on 11/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ChatMembersViewProtocol: class {
    var presenter: ChatMembersPresenterProtocol? { get set }
    func updateWith(viewModel: Dialog)
}

@objc public protocol ChatMembersModuleDelegate: class {
}

@objc public protocol ChatMembersPresenterProtocol: class, ContactPageModuleDelegate {
    weak var view: ChatMembersViewProtocol? { get set }
    weak var delegate: ChatMembersModuleDelegate? { get set }
    var router: ChatMembersRouterProtocol? { get set }
    var interactor: ChatMembersInteractorProtocol { get set }

    func viewWasLoaded()
    func chatWasUpdated(_ chat: Dialog)
    func deleteMember(_ member: ChatMember)

    func handleError(_ error: Error)
    func showContactPageWith(p2pChat: Dialog)
}

@objc public protocol ChatMembersRouterProtocol: class {
    weak var presenter: ChatMembersPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatMembersModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func presentContactPageViewWith(p2pChat: Dialog)
}

@objc public protocol ChatMembersInteractorProtocol: class {
    weak var presenter: ChatMembersPresenterProtocol? { get set }
    var chat: Dialog! { get }

    func updateWith(chat: Dialog)
    func deleteMember(_ member: ChatMember)
}

protocol ChatMembersDataManagerProtocol {
    func deleteMembers(_ members: [ChatMember], ofChat chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
}

@objc public protocol ChatMembersModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     chat: Dialog,
                     forDelegate delegate: ChatMembersModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}
