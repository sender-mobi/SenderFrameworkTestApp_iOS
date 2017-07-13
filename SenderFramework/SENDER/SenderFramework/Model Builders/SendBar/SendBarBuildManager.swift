//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarCreatorProtocol)
public protocol SendBarCreatorProtocol {
    func createSendBar() -> BarModel
    func deleteSendBar(_ sendBar: BarModel)
}

@objc(MWSendBarBuilderProtocol)
public protocol SendBarBuilderProtocol {

    init(sendBarItemBuildManager: SendBarItemBuildManagerProtocol)
    func setDataFrom(dictionary: [String: Any], to sendBar: BarModel) -> BarModel
    func update(sendBar: BarModel, with dictionary: [String: Any]) -> BarModel
}

@objc(MWSendBarBuildManagerProtocol)
public protocol SendBarBuildManagerProtocol {

    var sendBarCreator: SendBarCreatorProtocol { get }
    var sendBarBuilder: SendBarBuilderProtocol { get }

    init (sendBarCreator: SendBarCreatorProtocol, sendBarBuilder: SendBarBuilderProtocol)

    func sendBarWith(dictionary: [String: Any]) -> BarModel
    func setDataFrom(dictionary: [String: Any], to sendBar: BarModel) -> BarModel
    func update(sendBar: BarModel, with dictionary: [String: Any]) -> BarModel

    func deleteSendBar(_ sendBar: BarModel)
}

@objc(MWSendBarBuildManager)
public class SendBarBuildManager: NSObject, SendBarBuildManagerProtocol {

    public var sendBarCreator: SendBarCreatorProtocol
    public var sendBarBuilder: SendBarBuilderProtocol

    public required init (sendBarCreator: SendBarCreatorProtocol, sendBarBuilder: SendBarBuilderProtocol) {
        self.sendBarCreator = sendBarCreator
        self.sendBarBuilder = sendBarBuilder
        super.init()
    }

    public func sendBarWith(dictionary: [String: Any]) -> BarModel {
        let barModel = self.sendBarCreator.createSendBar()
        self.sendBarBuilder.setDataFrom(dictionary: dictionary, to: barModel)
        return barModel
    }

    public func setDataFrom(dictionary: [String: Any], to sendBar: BarModel) -> BarModel {
        return self.sendBarBuilder.setDataFrom(dictionary: dictionary, to: sendBar)
    }

    public func update(sendBar: BarModel, with dictionary: [String: Any]) -> BarModel {
        return self.sendBarBuilder.update(sendBar: sendBar, with: dictionary)
    }

    public func deleteSendBar(_ sendBar: BarModel) {
        self.sendBarCreator.deleteSendBar(sendBar)
    }
}
