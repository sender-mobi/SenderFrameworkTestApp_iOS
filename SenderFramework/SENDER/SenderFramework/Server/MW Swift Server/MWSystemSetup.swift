//
//  MWSystemSetup.swift
//  SENDER
//
//  Created by Eugene Gilko on 8/5/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

struct MWSystemSetup {
    
    let senderAPIVersion: Int = 10
    let serverType: String = "PROD" //"RC" "ALPHA" "TEST" // to do!!!
    var serverAPIURL: String {
    
        get {
            switch serverType {
            case "PROD":
                return "https://senderapi.com"
                
            case "RC":
                return "https://api-pre.sender.mobi"
                
            case "ALPHA":
                return "https://api-alpha.sender.mobi"
                
            case "TEST":
                return "https://api-dev.sender.mobi"
                
            default:
                return "https://senderapi.com"
            }
        }
    }
    
    var serverOnlineURL: String {
        return self.serverAPIURL + "/online"
    }
}