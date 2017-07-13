//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderDeauthorizationModel)
public class SenderDeauthorizationModel: NSObject {
    public var deviceUDID: String
    public var developerID: String
    public var deviceIMEI: String?
    public var companyID: String?

    public init(deviceUDID: String, developerID: String) {
        self.deviceUDID = deviceUDID
        self.developerID = developerID
        super.init()
    }
}