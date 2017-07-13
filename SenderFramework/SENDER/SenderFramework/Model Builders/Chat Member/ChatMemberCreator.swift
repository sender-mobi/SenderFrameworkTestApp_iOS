//
// Created by Roman Serga on 21/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatMemberCreator)
public class ChatMemberCreator: NSObject, ChatMemberCreatorProtocol {

    public func createChatMember() -> ChatMember {
        let dataFacade = CoreDataFacade.sharedInstance()
        guard let chatMember = dataFacade.getNewObject(withName: "ChatMember") as? ChatMember else {
            fatalError("Cannot get ChatMember from CoreDataFacade")
        }
        return chatMember
    }

    public func getOwner() -> Owner {
        return CoreDataFacade.sharedInstance().getOwner()
    }

    public func deleteMember(_ member: ChatMember) {
        CoreDataFacade.sharedInstance().delete(member)
    }

}
