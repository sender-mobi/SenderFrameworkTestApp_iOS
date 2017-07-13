//
//  MWNotificationCreator.swift
//  SENDER
//
//  Created by Eugene Gilko on 6/3/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

open class MWNotificationCreator: NSObject {

    static let shared = MWNotificationCreator()

    open func setNotificationMessageFromInfo(_ dictionary:[String:AnyObject], chat: Dialog) -> Message? {

        guard let packetID = dictionary["packetId"] as? Int,
              let model = dictionary["model"] as? [String: Any?],
              let notificationType = model["type"] as? String,
              let users = model["users"] as? [[String: Any]] else { return nil }

        let actionUserDictionary = model["actionUser"] as? [String: Any] ?? [:]
        let actionUserID = actionUserDictionary["userId"] as? String
        let ownerID = CoreDataFacade.sharedInstance().getOwner().ownerID
        let isOwnerAction = (actionUserID != nil && actionUserID! == ownerID)
        let actionUserName = (actionUserDictionary["name"] as? String) ?? "unknown_user".localized

        let names = ParamsFacade.sharedInstance().buildNotificationString(fromUsersDictionariesArray: users)

        let meInUsers = !(users.filter({
            let userID = $0["userId"] as? String
            return (userID != nil && userID == ownerID)
        }).isEmpty)

        let notificationString: String

        switch notificationType {
        case "add":
            if meInUsers {
                if users.count == 1 {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_add_to_chat_you"), actionUserName)
                }
                else {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_add_to_chat_with_you"), actionUserName, names)
                }
            }
            else {
                if isOwnerAction {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_you_add_to_chat"), names)
                }
                else {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_add_to_chat"), actionUserName, names)
                }
            }
        case "del":
            if meInUsers {
                if users.count == 1 {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_del_from_chat_you"), actionUserName)
                }
                else {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_del_from_chat_with_you"), actionUserName, names)
                }
            } else {
                if isOwnerAction {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_you_del_from_chat"), names)
                }
                else {
                    notificationString = String(format: SenderFrameworkLocalizedString("notify_user_del_from_chat"), actionUserName, names)
                }
            }
        case "leave":
            if isOwnerAction {
                notificationString = String(format:  SenderFrameworkLocalizedString("notify_you_leave_chat"))
            } else {
                notificationString = String(format:  SenderFrameworkLocalizedString("notify_user_leave_chat"), names)
            }
        default:
            return nil
        }

        let notification = self.createNotificationWith(data: dictionary,
                                                       text: notificationString,
                                                       users:names,
                                                       type: "NOTIFICATION",
                                                       packetID: packetID.description,
                                                       chat:chat)
        return notification
    }
    
    fileprivate func createNotificationWith(data:[String: Any],
                                            text: String,
                                            users: String?,
                                            type:String,
                                            packetID: String,
                                            chat: Dialog) -> Message? {

        guard let chatID = chat.chatID else { return nil }

        let mesID = MWMessageCreator.shared.createMoID(packetID, chatID: chatID)
        let notification = CoreDataFacade.sharedInstance().message(byId: mesID) ?? MWMessageCreator.shared.getNewRegMessage(mesID)

        let usersList = users ?? ""
        
        let textObject = ["text": text, "users": usersList]
        
        do {
            notification.data = try JSONSerialization.data(withJSONObject: textObject,
                                                           options:JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
        }

        notification.lasttext = text
        notification.type = type
        
        if let from = data["from"] as? String {
            notification.fromId = from
        }
        
        var creationTime : Date? = nil
        if let timeInterval = data["created"] as? Double {
            creationTime = Date.init(timeIntervalSince1970: (timeInterval / 1000))
        }

        CoreDataFacade.sharedInstance().setNewPacketID(packetID,
                                                       moID: nil,
                                                       andCreationTime:
                                                       creationTime,
                                                       for: notification)

        notification.chat = chat.chatID
        chat.addMessagesObject(notification)
        notification.deliver = "read"
        return notification
    }

    public func createEncryptionNotificationFrom(dictionary: [String: Any], inChat chat: Dialog) -> Message? {
        guard let packetID = dictionary["packetId"] as? Int,
              let model = dictionary["model"] as? [String: Any?] else { return nil }

        let actionUserDictionary = model["actionUser"] as? [String: Any] ?? [:]
        let actionUserID = actionUserDictionary["userId"] as? String
        let ownerID = CoreDataFacade.sharedInstance().getOwner().ownerID
        let isOwnerAction = (actionUserID != nil && actionUserID! == ownerID)
        let actionUserName = (actionUserDictionary["name"] as? String) ?? "unknown_user".localized
        let encryptionStatus: Bool
        if let key = model["encrKey"] as? String, !key.isEmpty { encryptionStatus = true }
        else { encryptionStatus = false }

        let notificationText: String

        if isOwnerAction {
            if encryptionStatus {notificationText = "notify_you_enabled_encryption".localized}
            else {notificationText = "notify_you_disabled_encryption".localized}
        } else {
            let phraseTemplate: String
            if encryptionStatus {phraseTemplate = "notify_user_enabled_encryption".localized}
            else { phraseTemplate = "notify_user_disabled_encryption".localized}
            notificationText = String(format: phraseTemplate, actionUserName)
        }

        let notification = self.createNotificationWith(data: dictionary,
                                                       text: notificationText,
                                                       users:nil,
                                                       type:"KEYCHAT",
                                                       packetID: packetID.description,
                                                       chat:chat)
        return notification
    }
}
