//
//  RequestBuilder.swift
//  SENDER
//
//  Created by Eugene Gilko on 5/21/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

import Foundation

typealias RequestCompletionHandler = () -> [String:String]

class RequestBuilder: NSObject {

    static let shared = RequestBuilder()

    var token = ""

    var backCometSession: URLSession?

    func createPOSTRequest(queueItem: MWTaskItem?, useLongSession: Bool) -> URLRequest {

        return self.buildPOSTRequest(self.getBaseULRParams(queueItem!), data: queueItem!.postData!, timeInterval: 30)
    }

//    private func buildGETRequest(path: String, data: AnyObject?, timeInterval: Int = 30) -> NSURLRequest! {
//
//        let request: NSMutableURLRequest = buildPOSTRequest(extraPath, urlExtraParams: self.getBaseULRParams(), data: nil, timeInterval: timeInterval) as! NSMutableURLRequest
//        request.HTTPMethod = "GET"
//
//        return request as NSURLRequest
//    }

    fileprivate func buildPOSTRequest(_ extraPath: String, data: AnyObject?, timeInterval: Int = 30) -> URLRequest! {

        let url: URL = URL(string: extraPath)!

        let request: NSMutableURLRequest = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: Double(timeInterval))

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Upgrade", forHTTPHeaderField: "Connection")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")

        if data != nil {

            var dataLenght = 0

            if data is NSData {
                request.httpBody = (data as! Data)
                dataLenght = (data as! Data).count
            }
            else {
                var fetchError:NSError? = nil
                var jsonData: Data? = nil
                do {
                    jsonData = try JSONSerialization.data(withJSONObject: data!, options:JSONSerialization.WritingOptions.prettyPrinted)

                } catch let error as NSError {
                    fetchError = error
                    jsonData = nil
                } catch {
                    fatalError()
                }

                if fetchError == nil {
                    request.httpBody = jsonData! as Data
                    dataLenght = (jsonData! as Data).count
                }
            }

            request.setValue("\(dataLenght)", forHTTPHeaderField: "Content-Length")

            MWLog.printLog("POST DATE REQUEST:" as AnyObject, data!)
        }
        return request as URLRequest!
    }

    fileprivate func getServerULR(_ queueItem: MWTaskItem) -> String {

        let verr = MWSystemSetup().senderAPIVersion
        let ssU = MWSystemSetup().serverAPIURL
        return ssU + "/" + "\(verr)" + "/" + queueItem.pathUrl!
    }

    fileprivate func getBaseULRParams(_ queueItem: MWTaskItem) -> String {

        queueItem.assignRidInfo(Int(Date().timeIntervalSince1970))

        var activeChatID = SenderCore.shared().activeChatsCoordinator.activeChatID ?? ""

        var preDict = [String: Any]()
        preDict = MWLocationFacade.sharedInstance().locationDictionary()
        preDict["token"] = SecGenerator.sharedInstance().tempTokken() as Any?
        preDict["udid"] = SenderCore.shared().deviceUDID as Any?
        preDict["ac"] = activeChatID as Any?
        preDict["rid"] = "\(queueItem.rid)" as Any?

        let outputString = self.convertDictionaryToString(preDict)

        return self.getServerULR(queueItem) + "?" + outputString
    }

    func convertDictionaryToString(_ dictionary: [String: Any]) -> String {

        var tempVal = ""
        var tempArray = [String]()

        for (k, v) in dictionary {

            if (v as! String).hasLenght() {
                tempVal = v as! String
            }
            else {
                tempVal = ""
            }

            tempArray.append("\(k)" + "=" + "\(tempVal)")
        }

        return tempArray.joined(separator: "&")
    }
}
