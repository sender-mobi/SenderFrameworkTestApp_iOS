//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ChatViewProtocol: class {
    var presenter: ChatPresenterProtocol? { get set }
    func updateWith(viewModel: Dialog)
}

@objc public protocol ChatModuleDelegate: class {
    func chatModuleDidFinish()
}

@objc public protocol ChatPresenterProtocol: class,
                                             ChatSettingsModuleDelegate,
                                             AddToChatModuleDelegate,
                                             QRScannerModuleDelegate {
    weak var view: ChatViewProtocol? { get set }
    weak var delegate: ChatModuleDelegate? { get set }
    var router: ChatRouterProtocol? { get set }
    var interactor: ChatInteractorProtocol { get set }

    func viewWasLoaded()
    func viewDidAppear()
    func viewDidDisappear()

    func chatWasUpdated(_ chat: Dialog)

    func callContact()
    func openChatSettings()
    func closeChatSettings()
    func addMembersToChat()
    func showQRScanner()

    func handleAction(_ action: [AnyHashable: Any])

    func closeChat()
    
    func setChatSettingsEnabled(_ enabled: Bool)
}

@objc public protocol ChatRouterProtocol: class {
    weak var presenter: ChatPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         model: ChatPresentationModelProtocol,
                         forDelegate delegate: ChatModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func showCallScreen()

    func showChatSettings()
    func dismissChatSettings()
    func updateChatSettingsWith(chat: Dialog)
    func setChatSettingsDisplayingEnabled(_ enabled: Bool)

    func presentAddMemberScreen()
    func dismissAddMemberScreen()

    func presentQRScanner()
    func dismissQRScanner()
}

@objc public class ChatPresentationModelOption: NSObject {
    public static let customBackgroundImage = "ChatPresentationModelCustomBackgroundImage"
    public static let customBackgroundImageURL = "ChatPresentationModelCustomBackgroundImageURL"
    public static let hideSendBar = "ChatPresentationModelOptionHideSendBar"
}

@objc public protocol ChatPresentationModelProtocol {
    var chatID: String { get }
    var chat: Dialog? { get }
    var actions: [[String: AnyObject]]? { get set }
    var options: [String: Any]? { get set }
}

@objc public protocol ChatInteractorProtocol: Chat {
    var chat: Dialog! { get set }
    var chatID: String! { get set }
    weak var presenter: ChatPresenterProtocol? { get set }

    var isActive: Bool { get set }

    func loadData()

    func updateWith(chat: Dialog)
    func updateWith(chatID: String)

    func callRobot(_ callRobotModel: CallRobotModel)

    func handleScannedQRString(_ qrString: String)
}

@objc public protocol ChatDataManagerProtocol {
    func chatWith(chatID: String) -> Dialog
    func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?)
    func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?)
}

@objc public protocol ChatModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     model: ChatPresentationModelProtocol,
                     forDelegate delegate: ChatModuleDelegate?,
                     completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}
