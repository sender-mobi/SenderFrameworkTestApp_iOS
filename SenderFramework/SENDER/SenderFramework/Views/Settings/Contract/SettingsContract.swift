//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol SettingsViewProtocol: class {
    var presenter: SettingsPresenterProtocol? { get set }
    func updateWith(viewModel: Settings)
    func updateWith(blockedUsersCount: Int)
    func showRestartWarning()
    func showLanguagesChooseWith(languages: [String])
    func showLocationNotAvailableWarning()
}

@objc public protocol SettingsModuleDelegate: class {
    func settingsModuleDidFinish()
}

@objc public class Language: NSObject {
    public typealias LanguageType = String

    static let english = "English"
    static let russian = "Русский"
    static let ukrainian = "Українська"
}

@objc public protocol SettingsPresenterProtocol: class, EntityPickerModuleDelegate {

    weak var view: SettingsViewProtocol? { get set }
    weak var delegate: SettingsModuleDelegate? { get set }
    var router: SettingsRouterProtocol? { get set }
    var interactor: SettingsInteractorProtocol { get set }

    func viewWasLoaded()
    func settingsWereUpdated(_ settings: Settings)
    func blockedUsersCountWasUpdated(_ blockedUsersCount: Int)

    func showAvailableLanguages()
    func changeLanguageTo(_ newLanguage: Language.LanguageType)

    func changeSendReadStatusTo(_ newStatus: Bool)
    func changeLocationMonitoringStatusTo(_ newStatus: Bool)
    func changeSoundStatusTo(_ newStatus: Bool)
    func changeNotificationSoundTo(_ newStatus: Bool)
    func changeVibrationStatusTo(_ newStatus: Bool)
    func changeFlashStatusTo(_ newStatus: Bool)

    func showBitcoinWallet()
    func clearChatHistory()
    func disableDevice()
    func showActiveDevices()

    func showBlockedUsers()

    func restart()
    func cancelRestart()

    func prepareForRestartWith(completion: @escaping ((Bool) -> Void))

    func closeSettings()
}

@objc public protocol SettingsRouterProtocol: class {
    weak var presenter: SettingsPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: SettingsModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func presentBitcoinWalletView()
    func presentActiveDevicesView()
    func presentBlockedUsersView()
    func dismissBlockedUsersView()
}

@objc public protocol SettingsInteractorProtocol: class {
    weak var presenter: SettingsPresenterProtocol? { get set }
    var settings: Settings! { get }

    func loadData()

    func updateWith(settings: Settings)

    func getAvailableLanguages() -> [String]

    func changeSendReadStatusTo(_ newStatus: Bool)
    func changeLanguageTo(_ newLanguage: String)
    func changeLocationMonitoringStatusTo(_ newStatus: Bool, completion: @escaping ((Bool, Error?) -> Void))
    func changeSoundStatusTo(_ newStatus: Bool)
    func changeNotificationSoundTo(_ newStatus: Bool)
    func changeVibrationStatusTo(_ newStatus: Bool)
    func changeFlashStatusTo(_ newStatus: Bool)

    func clearChatHistory()
    func disableDevice()
}

protocol SettingsDataManagerProtocol {
    func saveSettings(_ settings: Settings, completionHandler: ((Bool, Error?) -> Void)?)
    func saveLanguage(_ language: String, completion: ((Bool, Error?) -> Void)?)
    func getBlockedChats(completion: (([Dialog], Error?) -> Void)?)
}

protocol SettingsLocationManagerProtocol {
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func isLocationUsageAllowed(_ completion:@escaping ((Bool) -> Void))
}

protocol SettingsEraserProtocol {
    func clearChatHistoryWith(completion: ((Bool, Error?) -> Void)?)
    func disableDeviceWith(completion: ((Bool, Error?) -> Void)?)
}

@objc public protocol SettingsModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     settings: Settings,
                     forDelegate delegate: SettingsModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}
