//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ChatSettingsViewProtocol: class {
    var presenter: ChatSettingsPresenterProtocol? { get set }

    func updateWith(viewModel: Dialog)
}

@objc public protocol ChatSettingsModuleDelegate: class {
    func chatSettingsModuleDidUpdateChat(_ chat: Dialog)
}

@objc public protocol ChatSettingsPresenterProtocol: class, ChatEditorModuleDelegate,
                                                     ChatMembersModuleDelegate,
                                                     ContactPageModuleDelegate,
                                                     AddToChatModuleDelegate {
    weak var view: ChatSettingsViewProtocol? { get set }
    weak var delegate: ChatSettingsModuleDelegate? { get set }
    var router: ChatSettingsRouterProtocol? { get set }
    var interactor: ChatSettingsInteractorProtocol { get set }

    func viewWasLoaded()
    func editChat()
    func showChatMembers()
    func leaveChat()
    func addParticipants()
    func showContactPage()

    func chatWasUpdated(_ chat: Dialog)

    func changeEncryptionStateTo(_ newEncryptionState: Bool)
    func changeFavoriteStateTo(_ newFavoriteState: Bool)
    func changeBlockStateTo(_ newBlockState: Bool)

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme)
    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType)
    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType)
    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType)
    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType)
    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType)
}

@objc public protocol ChatSettingsRouterProtocol: class {
    weak var presenter: ChatSettingsPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatSettingsModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func presentChatEditScreen()
    func dismissChatEditScreen()
    func presentMembersScreen()
    func presentAddMemberScreen()
    func dismissAddMemberScreen()
    func presentContactPage()
}

@objc public protocol ChatSettingsInteractorProtocol: class {
    weak var presenter: ChatSettingsPresenterProtocol? { get set }
    var chat: Dialog! { get }

    func updateWith(chat: Dialog)

    func addMembers(_ members: [Dialog])
    func leaveChat()

    func changeEncryptionStateTo(_ newEncryptionState: Bool)
    func changeFavoriteStateTo(_ newFavoriteState: Bool)
    func changeBlockStateTo(_ newBlockState: Bool)

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme)
    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType)
    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType)
    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType)
    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType)
    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType)
}

protocol ChatSettingsDataManagerProtocol {

    func add(members: [Dialog],
             toChat chat: Dialog,
             completionHandler: ((Dialog?, Error?) -> Void)?)

    func setEncryptionStateOf(chat: Dialog,
                              encryptionState: Bool,
                              completionHandler: ((Dialog?, Error?) -> Void)?)

    func changeSettingsOf(chat: Dialog,
                          newSettings: ChatSettingsEditModel,
                          completionHandler: ((Dialog?, Error?) -> Void)?)

    func leave(chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
}

@objc public protocol ChatSettingsModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     chat: Dialog,
                     forDelegate delegate: ChatSettingsModuleDelegate?,
                     completion: (() -> Void)?)
    func updateWith(chat: Dialog)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}
