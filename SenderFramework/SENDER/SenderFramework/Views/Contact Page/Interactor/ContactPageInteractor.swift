//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ContactPageInteractor: ContactPageInteractorProtocol {
    weak var presenter: ContactPagePresenterProtocol?
    private(set) var p2pChat: Dialog!

    func updateWith(p2pChat: Dialog) {
        self.p2pChat = p2pChat
        self.presenter?.chatWasUpdated(p2pChat)
    }

}
