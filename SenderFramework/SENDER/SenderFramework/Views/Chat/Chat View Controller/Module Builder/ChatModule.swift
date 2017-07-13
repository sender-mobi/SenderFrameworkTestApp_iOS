//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatModule: NSObject, ChatModuleProtocol {

    private weak var router: ChatRouterProtocol?

    public var chatSettingsModule: ChatSettingsModuleProtocol
    public var addToChatModule: AddToChatModuleProtocol
    public var qrScannerModule: QRScannerModuleProtocol

    public init(chatSettingsModule: ChatSettingsModuleProtocol,
                addToChatModule: AddToChatModuleProtocol,
                qrScannerModule: QRScannerModuleProtocol) {
        self.chatSettingsModule = chatSettingsModule
        self.addToChatModule = addToChatModule
        self.qrScannerModule = qrScannerModule
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            model: ChatPresentationModelProtocol,
                            forDelegate delegate: ChatModuleDelegate?,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presenter?.interactor.chat = model.chat
            self.router?.presentViewWith(wireframe: wireframe,
                                         model: model,
                                         forDelegate: delegate,
                                         completion: completion)
            return
        }

        let chatEditManagerInput = ChatEditManagerInput()
        let chatDataManager = ChatDataManager(input: chatEditManagerInput)
        let chatInteractor = ChatInteractor(dataManager: chatDataManager)
        let chatRouter = ChatRouter(chatSettingsModule: self.chatSettingsModule,
                                    addToChatModule: self.addToChatModule,
                                    qrScannerModule: self.qrScannerModule)
        let chatPresenter = ChatPresenter(interactor: chatInteractor, router: chatRouter)
        if let chat = model.chat {
            chatInteractor.updateWith(chat: chat)
        } else {
            chatInteractor.updateWith(chatID: model.chatID)
        }
        chatInteractor.presenter = chatPresenter
        MWCometParser.shared.forceOpenHandler = chatInteractor
        MWCometParser.shared.soundPlayer = chatInteractor
        SenderCore.shared().activeChatsCoordinator.addChat(chatInteractor)
        chatRouter.presenter = chatPresenter
        chatRouter.presentViewWith(wireframe: wireframe, model: model, forDelegate: delegate, completion: completion)
        self.router = chatRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }
}

extension ChatInteractor: MWCometParserForceOpenHandler {
    @objc func cometParser(_ parser: MWCometParser, didReceiveForceOpenFormWith chatID: String) {
        self.updateWith(chatID: chatID)
    }
}

extension ChatInteractor: MWCometParserSoundPlayer {
    @objc func cometParser(_ parser: MWCometParser,
                           didReceiveMessage message: Message,
                           withData data: [String: AnyObject]) {
        guard !self.isActive || message.dialog.chatID != self.chatID else { return }
        SenderCore.shared().cometParser(parser, didReceiveMessage: message, withData: data)
    }
}
