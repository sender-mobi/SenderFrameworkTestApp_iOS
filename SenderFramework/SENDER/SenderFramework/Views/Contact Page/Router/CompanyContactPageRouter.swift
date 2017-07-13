//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyContactPageRouter: ContactPageRouter<CompanyPageViewController> {

    override func buildContactView() -> CompanyPageViewController {
        return CompanyPageViewController.loadFromSenderFrameworkStoryboardWith(name: "ContactPageViewController")
    }

}
