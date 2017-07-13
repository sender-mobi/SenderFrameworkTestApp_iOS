//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderFullAuthorizationModule)
public class SenderFullAuthorizationModule: NSObject, SenderAuthorizationModuleProtocol {

    private var authorizationPresenter: SenderFullAuthorizationPresenter

    public init(navigationController: UIKit.UINavigationController,
                delegate: SenderAuthorizationModuleDelegate?) {
        let authorizationServer = SenderFullAuthorizationServer()
        let authorizationDataManager = SenderAuthorizationDataManager()
        let authorizationInteractor = SenderFullAuthorizationInteractor(server: authorizationServer,
                                                                        dataManager: authorizationDataManager)
        let authorizationRouter = SenderFullAuthorizationRouter(navigationController: navigationController)
        self.authorizationPresenter = SenderFullAuthorizationPresenter(authorizationManager: authorizationInteractor,
                                                                  router: authorizationRouter)
        self.authorizationPresenter.delegate = delegate
        super.init()
    }

    public func startAuthorizationWith(model: SenderAuthorizationModel) {
        self.authorizationPresenter.startAuthorizationWith(model: model)
    }

    public func deauthorizeWith(model: SenderDeauthorizationModel) {
        self.authorizationPresenter.deauthorizeWith(model: model)
    }

    public func startEnteringName() {
        self.authorizationPresenter.startEnteringNameWith(completion: nil)
    }

}
