//
//  MWConnectionsCoordinator.swift
//  SENDER
//
//  Created by Eugene Gilko on 1/29/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

enum QueueItemState: Int {
    case in_QEUEUE = 0
    case in_PROGRESS = 1
    case fail_SEND = -1
    case finished = 2
}

enum ServerType: Int {
    case prod
    case pr
    case test
}

class MWConnectionsCoordinator : NSObject {
    
    fileprivate let prodServerURL = "https://senderapi.com"
    fileprivate let pRServerURL = "https://api-rc.sender.mobi"
    fileprivate let testServerURL = "https://api-dev.sender.mobi"
    fileprivate let serverID: ServerType = .prod
    
    override init() {
        super.init()
        setupConnectionNottification()
    }
    
    let reachability:Reachability? = Reachability(hostName: "senderapi.com")
    
    func hasConnectivity() -> Bool {
        
        let networkStatus: Int = reachability!.currentReachabilityStatus().rawValue
        return networkStatus != 0
    }
    
    func setupConnectionNottification() -> Void {
        
        NotificationCenter.default.addObserver(self, selector: #selector(MWConnectionsCoordinator.reachabilityChanged(_:)), name:NSNotification.Name.reachabilityChanged, object: nil)
        
        reachability!.startNotifier();
    }
    
    func reachabilityChanged(_ note: Notification) {
        
        let reachabilityState: Reachability = note.object as! Reachability;
        
        let networkStatus: NetworkStatus = reachabilityState.currentReachabilityStatus()
        
        switch networkStatus {
            
        case ReachableViaWiFi, ReachableViaWWAN:
            runControllers()
            break
        case NotReachable:
            stopControllers()
            break
        default: break
        }
    }
    
    func runControllers() -> Bool {
        return true
    }
    
    func stopControllers() -> Bool {
        return true
    }

    func suspendAllActiveTask() -> Bool {
        
        return true
    }
    
    func serverUrlFromMode() -> String {
        
        let curULR: String
        switch serverID {
            
        case .prod:
            curULR = prodServerURL
        case .pr:
            curULR = pRServerURL
        default:
            curULR = testServerURL
        }
        
        return curULR
    }
    
//    func getExtraULRParams() -> [String:String] {
//        
//        return["one":"one"]
//    }
    
//    func getExtraULRParams() -> [String:String] {
//
//        if (MWDataFacade.shared.deviceUDID == nil) {
//            MWDataFacade.shared.deviceUDID  = MWDataFacade.shared.encritProcessor.generateUDID()
//        }
//
//        return ["token":token,"udid":MWDataFacade.shared.deviceUDID!]
//    }
//
//    func getServerURLPath(extraPath: String, urlExtraParams:[String:String]?) -> String {
//
//        var serverULR = serverUrlFromMode() + "/" + SenderAppDelegate.sharedDelegate.getApiVersion() + "/" + extraPath
//
//        if urlExtraParams != nil {
//
//            serverULR += "?" + StringUrlEncoder.convertDictionaryToULRString(urlExtraParams!)
//        }
//
//        return serverULR
//    }
    
    func changeServerURL() -> Void {
        
    }
    
    func chekResponse(_ response: URLResponse?) -> Bool {
        
        if let resp = response as! HTTPURLResponse! {
            
            if resp.statusCode == 200 {
                return false
            }
            else {
                changeServerURL()
            }
        }
        return true
    }
    
    func validateServerResponse(_ result : NSDictionary?) -> Bool {
        
        let code = result!["code"] as! NSNumber
        
        switch code {
        case 0:
            return true
        case 1:
            //            MWDataFacade.shared.recalculateToken(result!["challenge"] as! String)
            return false
        case 3:
            return false
        case 5:
            return false
        default:
            return false
        }
    }
    
    func convertStringToURLString(_ source: [String:String]?) -> String! {
        
        var resArray = [String]()
        
        for (key, val) in source! {
            
            let partString = (key)+"="+(val)
            
            resArray.append(partString)
        }
        return resArray.joined(separator: "&")
    }
}
