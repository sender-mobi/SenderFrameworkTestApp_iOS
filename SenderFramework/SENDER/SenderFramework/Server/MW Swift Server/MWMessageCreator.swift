//
//  MWMessageCreator.swift
//  SENDER
//
//  Created by Eugene Gilko on 6/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

func classComponentsFrom(classString: String) -> (formID: String?, robotID: String?, companyId: String?) {
    let classArray = classString.components(separatedBy: ".")

    var formID: String?
    var robotID: String?
    var companyID: String?

    if classArray.count >= 2 {
        if !classArray[0].isEmpty { formID = classArray[0] }
        if !classArray[1].isEmpty { robotID = classArray[1] }
        if classArray.count > 2, !classArray[2].isEmpty { companyID = classArray[2] }
    }

    return (formID, robotID, companyID)
}

@objc open class MWMessageCreator: NSObject {

    open static let shared = MWMessageCreator()

    open func setMessageDataFromInfo(_ data:[String:AnyObject], chat: Dialog) -> Message? {

        guard let chatID = chat.chatID else { return nil }

        let packetID = data["packetId"] as? Int

        guard let linkID = (data["linkId"] as? Int) ?? packetID else { return nil }

        let messageID = self.createMoID(linkID.description, chatID: chatID)

        if let linkedMessage = CoreDataFacade.sharedInstance().message(byId: messageID) {

            var currentPacketID = 0
            if linkedMessage.packetID != nil {
                currentPacketID = (linkedMessage.packetID as NSString).integerValue
            }

            if let packetID = packetID {
                if currentPacketID < packetID {
                    CoreDataFacade.sharedInstance().setNewPacketID(String(packetID), for: linkedMessage)
                    self.updateMessageInfo(linkedMessage, data: data)
                    linkedMessage.editedMessage = true
                    SenderCore.shared().interfaceUpdater.messagesWereChanged([linkedMessage])
                    return linkedMessage
                } else {
                    if linkID == packetID, let timeInterval = data["created"] as? Double {
                        let creationTime = Date(timeIntervalSince1970: (timeInterval / 1000))
                        CoreDataFacade.sharedInstance().setNewPacketID(nil, moID: nil, andCreationTime: creationTime, for: linkedMessage)
                        SenderCore.shared().interfaceUpdater.messagesWereChanged([linkedMessage])
                        return linkedMessage
                    }
                }
            }
            else {
                return nil
            }
        }

        if packetID != nil {

            guard CoreDataFacade.sharedInstance().message(byId: messageID) == nil else { return nil }

            let message = self.getNewRegMessage(messageID)

            self.operateWithMessage(message, data: data, packetID: packetID!.description)
                
            if message.robotId != nil && message.robotId == "contact" {
                message.linkID = "contactPage"
//                    chat.companyCard = message
                SENDER_SHARED_CORE.interfaceUpdater.messagesWereChanged([message])
            } else {
                message.chat = chatID
                chat.addMessagesObject(message)
                SENDER_SHARED_CORE.interfaceUpdater.messagesWereChanged([message])
            }

            if chat.isP2P {
                
                if message.type != nil && message.type == "TEXT" {
                
                    let mEncr = message.encrypted.boolValue
                    let cEncr = chat.isEncrypted()
                 
//                    if mEncr && !cEncr {
//                        chat.encryptedMode(true)
//                    }
//                    else if !mEncr && cEncr {
//                        chat.encryptedMode(false)
//                    }
                    
                    if let testString = data["text"] as? String {
                        
                        if !testString.hasLenght() {
                            message.encrypted = false;
                            message.lasttext = "Message deleted".localized
                        }
                    }
                }
            }
        
            return message
        }
        
        return nil
    }

    open func companyCardWith(dictionary: [String: Any], chat: Dialog) -> CompanyCard {

        let companyCard = chat.companyCard ?? CoreDataFacade.sharedInstance().createCompanyCard()
        self.operateWithMessage(companyCard, data: dictionary, packetID: "-1")
        self.updateMessageInfo(companyCard, data: dictionary)
        companyCard.linkID = "contactPage"
        chat.companyCard = companyCard
        companyCard.chat = chat.chatID
        SENDER_SHARED_CORE.interfaceUpdater.messagesWereChanged([companyCard])
        return companyCard
    }
    
    fileprivate func operateWithMessage(_ message: Message, data: [String: Any], packetID: String) {

        var creationTime : Date? = nil
//        let packetID = data["packetId"]?.description
        let linkID = (data["linkId"] as? String) ?? packetID

        if let timeInterval = data["created"] as? Double {
            creationTime = Date(timeIntervalSince1970: (timeInterval / 1000))
        }

        if linkID != nil { message.linkID = linkID }
        
        if let from = data["from"] as? String {
            message.fromId = from
        }

        CoreDataFacade.sharedInstance().setNewPacketID(packetID, moID: nil, andCreationTime: creationTime, for: message)
        self.updateMessageInfo(message, data: data)
    }
    
    fileprivate func updateMessageInfo(_ message: Message, data:[String: Any]) {

        if let classS = data["class"] as? String {
            let classComponents = classComponentsFrom(classString: classS)

            message.classRef = classS
            message.formId = classComponents.formID ?? ""
            message.robotId = classComponents.robotID
            message.companyId = classComponents.companyId
        }
        
        if let procID = data["procId"] as? String {
            message.procId = procID
        }
        
        let viewModel = data["view"] as? [String:AnyObject]
        
        if viewModel != nil && viewModel!.count > 0 {
            // build form
            self.constructFormMessage(message, model: data)
        }
        else if data["class"] != nil {
            
            switch data["class"] as! String {
            case "text":
                self.constructTextMessage(message, model: data["model"] as? [String:AnyObject])
                break
            case "image":
                self.constructImageMessage(message, model: data["model"] as? [String:AnyObject])
            case "audio":
                self.constructAudioMessage(message, model: data["model"] as? [String:AnyObject])
            case "video":
                self.constructVideoMessage(message, model: data["model"] as? [String:AnyObject])
            case "file":
                self.constructFileMessage(message, model: data["model"] as? [String:AnyObject])
            case "sticker":
                self.constructStickerMessage(message, model: data["model"] as? [String:AnyObject])
            case "vibro":
                self.constructVibroMessage(message, model: data["model"] as? [String:AnyObject])
            case "location":
                self.constructLocationMessage(message, model: data["model"] as? [String:AnyObject])
            default:
                break
            }
        }
    }
    
    fileprivate func constructTextMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        if let messageDict = model {

            var pKey = ""
            
            if let key = messageDict["pkey"] as? String {
                pKey = key as String
            }

            if let messageText = messageDict["text"] as? String {
                message.data = ParamsFacade.sharedInstance().nsData(from: ["text" : messageText, "pkey" : pKey])

                if messageDict["encrypted"]?.boolValue != nil && messageDict["encrypted"]!.boolValue {
                    message.encrypted = true
                    message.textMessage = ""
                    message.lasttext = "lst_msg_text_for_lc_encrypted_text_ios".localized
                } else {
                    message.encrypted = false

                    if messageText.hasLenght() {
                        message.textMessage = messageText
                    } else {
                        message.textMessage = "Message deleted".localized
                    }
                    message.lasttext = message.textMessage
                }
            }
            
            message.type = "TEXT"
        }
    }
    
    fileprivate func constructVideoMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        self.createFileObjectWithModel(model! as AnyObject, message: message, type: "VIDEO", lastText: "lst_msg_text_for_lc_video_ios")
    }
    
    fileprivate func constructImageMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        self.createFileObjectWithModel(model! as AnyObject, message: message, type: "IMAGE", lastText: "lst_msg_text_for_lc_image_msg_ph_ios")
    }
    
    fileprivate func constructFileMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        self.createFileObjectWithModel(model! as AnyObject, message: message, type: "FILE", lastText: "lst_msg_text_for_lc_file_ios")
    }
    
    fileprivate func constructAudioMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        self.createFileObjectWithModel(model! as AnyObject, message: message, type: "AUDIO", lastText: "lst_msg_text_for_lc_voice_message_ios")
    }
    
    fileprivate func constructLocationMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        message.type = "SELFLOCATION"
        message.lasttext = "lst_msg_text_for_lc_location_ios".localized
        message.modelData = ParamsFacade.sharedInstance().nsData(from: model!)
    }
    
    fileprivate func constructStickerMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        message.type = "STICKER"
        message.lasttext = "lst_msg_text_for_lc_sticker_msg_ph_ios".localized
        message.data = self.createDataFromModel(model!)
    }
    
    fileprivate func constructVibroMessage(_ message: Message, model:[String:AnyObject]?) -> Void {
        
        message.type = "VIBRO"
        message.lasttext = "lst_msg_text_for_lc_vibro_msg_ph_ios".localized
        message.data = self.createDataFromModel(model!)
    }
    
    fileprivate func constructFormMessage(_ message: Message, model:[String: Any]?) -> Void {
        
        message.type = "FORM"

        if let modelDict = model?["model"] as? [String: Any], let title = modelDict["title"] as? String {
            message.lasttext = title
        }
        else if let modelClass = model?["class"] as? String, modelClass == "kickass.alert.sender" {
            message.lasttext = "Yo!"
        }
        else {
            message.lasttext = "lst_msg_text_for_lc_form_msg_ph_ios".localized
        }

        if let modelView = model?["view"] as? NSString {
            message.data = modelView.data(using: String.Encoding.utf8.rawValue)
        } else {
            message.data = try? JSONSerialization.data(withJSONObject: model!["view"]!, options:JSONSerialization.WritingOptions.prettyPrinted)
        }
    }

    fileprivate func createFileObjectWithModel(_ model: AnyObject, message:Message, type: String, lastText: String) -> Void {
        
        message.type = type
        message.lasttext = lastText.localized
        let fileObj = CoreDataFacade.sharedInstance().getNewObject(withName: "File") as! File
        fileObj.setDataFrom(model as! [AnyHashable: Any])
        message.file = fileObj
        self.startDownloadInfo(message)
    }
    
    fileprivate func startDownloadInfo(_ message: Message) -> Void {
        FileManager.shared().downloadData(for: message)
    }
    
    fileprivate func createDataFromModel(_ model:[String:AnyObject]) -> Data {
        
        var jsonData = Data()
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: model, options:JSONSerialization.WritingOptions.prettyPrinted)
        }
        catch {
        }
        
        return jsonData
    }
    
    func createMoID(_ packetID: String, chatID: String) -> String {
        
        return chatID+"<<"+packetID
    }
    
    func getNewRegMessage(_ messageID: String) -> Message {
        let newMessage: Message = CoreDataFacade.sharedInstance().newMessageModel()
        newMessage.moId = messageID
        return newMessage
    }
}
