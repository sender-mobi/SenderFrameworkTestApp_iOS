//
// Created by Roman Serga on 14/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatEditManagerInput)
public class ChatEditManagerInput: NSObject, ChatEditManagerInputProtocol {

    public func getInfoFor(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().getChatWithID(chatID, requestHandler: requestHandler)
    }

    public func addMembersWith(userIDs: [String],
                               toChatWithID chatID: String,
                               requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().addMembers(userIDs, toChat: chatID, requestHandler: requestHandler)
    }

    public func leaveChatWith(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().leaveChat(chatID, completionHandler: requestHandler)
    }

    public func edit(chatID: String,
                     withName name: String?,
                     description: String?,
                     imageURL: String?,
                     requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeChat(chatID,
                                                 withName: name,
                                                 description: description,
                                                 photoUrl: imageURL,
                                                 requestHandler: requestHandler)
    }

    public func uploadChatImageData(_ imageData: Data, completion: @escaping ((URL?, Error?) -> Void)) {

        let message = ["type": "IMAGE",
                       "moId": "0",
                       "target": "chat_logo"]
        ServerFacade.sharedInstance().uploadFile(toServer: imageData,
                                                 previewImage: imageData,
                                                 byMessage: message) { response, error in
                    guard error == nil else { completion(nil, error); return }

                    guard let urlString = response?["url"] as? String, let url = URL(string: urlString) else {
                        let error = NSError(domain: "Cannot get image URL", code: 1)
                        completion(nil, error)
                        return
                    }
                    completion(url, nil)
                }
    }

    public func sendReadFor(message: Message) {
        ServerFacade.sharedInstance().sayReadStatus(message)
    }

    public func saveP2PChatWith(userID: String,
                                requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().saveP2PChat(withUserID: userID, completionHandler: requestHandler)
    }

    public func deleteP2PChatWith(userID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().deleteP2PChat(withUserID: userID, completionHandler: requestHandler)
    }

    public func changeP2PChatWith(userID: String,
                                  name: String,
                                  phone: String,
                                  requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeP2PChat(withUserID: userID,
                                                    withName: name,
                                                    phone: phone,
                                                    completionHandler: requestHandler)
    }

    public func changeSettingsOfChatWith(chatID: String,
                                         settingsDictionary: [String: Any],
                                         requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeSettingsOfChat(withID: chatID,
                                                           settingsDictionary: settingsDictionary,
                                                           withCompletionHandler: requestHandler)
    }

    public func changeChatEncryptionStateWith(chatID: String,
                                              encryptionState: Bool,
                                              keys: [String: String]?,
                                              senderKey: String?,
                                              requestHandler: @escaping  SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeEncryptionStateOfChat(withID: chatID,
                                                                  encryptionState: encryptionState,
                                                                  keys: keys,
                                                                  senderKey: senderKey,
                                                                  completionHandler: requestHandler)
    }

    public func deleteMembersWith(userIDs: [String],
                                  toChatWithID chatID: String,
                                  requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().deleteMembers(withUserIDs: userIDs,
                                                    fromChatWithID: chatID, requestHandler: requestHandler)
    }
}
