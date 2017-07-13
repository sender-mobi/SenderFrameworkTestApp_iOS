//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class CallRobotModule: ChatModule, CallRobotModuleProtocol {

    private weak var router: ChatRouterProtocol?

    public func presentWith(wireframe: ViewControllerWireframe,
                            callRobotModel: CallRobotModelProtocol,
                            forDelegate delegate: ChatModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let callRobotDataManager = ChatDataManager(input: chatEditManagerInput)
        let callRobotInteractor = CallRobotInteractor(dataManager: callRobotDataManager)
        callRobotInteractor.callRobotModel = callRobotModel

        let chatID: String
        if let robotModelChatID = callRobotModel.chatID {
            chatID = robotModelChatID
        } else {
            chatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
        }
        let chatPresentationModel = ChatPresentationModel(chatID: chatID)

        callRobotInteractor.updateWith(chatID: chatPresentationModel.chatID)

        let callRobotRouter = ChatRouter(chatSettingsModule: self.chatSettingsModule,
                                             addToChatModule: self.addToChatModule,
                                             qrScannerModule: self.qrScannerModule)
        let callRobotPresenter = ChatPresenter(interactor: callRobotInteractor, router: callRobotRouter)

        callRobotInteractor.presenter = callRobotPresenter
        callRobotRouter.presenter = callRobotPresenter

        MWCometParser.shared.soundPlayer = callRobotInteractor
        MWCometParser.shared.forceOpenHandler = callRobotInteractor
        SenderCore.shared().activeChatsCoordinator.addChat(callRobotInteractor)

        callRobotRouter.presentViewWith(wireframe: wireframe,
                                            model: chatPresentationModel,
                                            forDelegate: delegate,
                                            completion: completion)
        self.router = callRobotRouter
    }

    override public func dismiss(completion: (() -> Void)?) {
        super.dismiss(completion: nil)
        self.router?.dismissView(completion: completion)
    }

    override public func dismissWithChildModules(completion: (() -> Void)?) {
        super.dismissWithChildModules(completion: nil)
        self.router?.dismissAllViews(completion: completion)
    }
}

extension CallRobotModel {
    static var activeDevices: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "devices", companyID: "sender")
        return callRobotModel
    }

    static var topUpMobile: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "payMobile", companyID: "sender")
        return callRobotModel
    }

    static var transferMobile: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "sendMoney", companyID: "sender")
        return callRobotModel
    }

    static var wallet: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "wallet", companyID: "sender")
        return callRobotModel
    }

    static var store: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "shop", companyID: "sender")
        return callRobotModel
    }

    static var createRobot: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "92535", companyID: "sender")
        return callRobotModel
    }
}
