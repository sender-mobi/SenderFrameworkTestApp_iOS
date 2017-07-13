//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ContactPageViewProtocol: class {
    var presenter: ContactPagePresenterProtocol? { get set }
    func updateWith(viewModel: Dialog)
}

@objc public protocol ContactPageModuleDelegate: class {
    func contactPageModuleDidFinish()
}

@objc public protocol ContactPagePresenterProtocol: class {
    weak var view: ContactPageViewProtocol? { get set }
    weak var delegate: ContactPageModuleDelegate? { get set }
    var router: ContactPageRouterProtocol? { get set }
    var interactor: ContactPageInteractorProtocol { get set }

    func goToChatWith(actions: [[String: AnyObject]]?)
    func viewWasLoaded()
    func chatWasUpdated(_ chat: Dialog)
    func handleAction(_ action: [AnyHashable: Any])

    func closeContactPage()
}

@objc public protocol ContactPageRouterProtocol: class {
    weak var presenter: ContactPagePresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ContactPageModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)

    func presentChatWith(actions: [[String: AnyObject]]?)
    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol)
}

@objc public protocol ContactPageInteractorProtocol: class {
    weak var presenter: ContactPagePresenterProtocol? { get set }
    var p2pChat: Dialog! { get }

    func updateWith(p2pChat: Dialog)
}

protocol ContactPageDataManagerProtocol {
}

@objc public protocol ContactPageModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     p2pChat: Dialog,
                     forDelegate delegate: ContactPageModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}