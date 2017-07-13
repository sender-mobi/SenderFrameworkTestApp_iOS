//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class HumanContactPageRouter: ContactPageRouter<ContactPageViewController> {

    override func buildContactView() -> ContactPageViewController {
        return ContactPageViewController.loadFromSenderFrameworkStoryboardWith(name: "ContactPageViewController")
    }

}
