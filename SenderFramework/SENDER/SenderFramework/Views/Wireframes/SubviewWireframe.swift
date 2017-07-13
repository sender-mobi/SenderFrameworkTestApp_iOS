//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol SubviewWireframeEventsHandler {
    @objc func prepareForPresentationWith(subviewWireframe: SubviewWireframe)
    @objc func prepareForDismissalWith(subviewWireframe: SubviewWireframe)
}

@objc public class SubviewWireframe: NSObject, ViewControllerWireframe {

    public private(set) weak var rootView: UIViewController?
    var animationDuration: TimeInterval = 0.3
    public private(set) weak var superview: UIView?
    public var animatedPresentation: Bool = false

    public init(parentViewController: UIViewController, superView: UIView) {
        self.rootView = parentViewController
        self.superview = superView
        super.init()
    }

    public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView, let superview = self.superview else { return }

        let initialAlphaValue = view.view.alpha
        self.callPrepareForPresentationWith(view: view)
        rootView.addChildViewController(view)
        superview.addSubview(view.view)
        view.view.translatesAutoresizingMaskIntoConstraints = false
        let layoutAttributes: [NSLayoutAttribute] = [.top, .leading, .trailing, .bottom]
        for layoutAttribute in layoutAttributes {
            let constraint = NSLayoutConstraint(item: superview,
                                                attribute: layoutAttribute,
                                                relatedBy: .equal,
                                                toItem: view.view,
                                                attribute: layoutAttribute,
                                                multiplier: 1.0,
                                                constant: 0.0)
            superview.addConstraint(constraint)
        }

        if self.animatedPresentation {
            view.view.alpha = 0
            UIView.animate(withDuration: self.animationDuration,
                           animations: { view.view.alpha = initialAlphaValue },
                           completion: { _ in completion?() })
        } else {
            completion?()
        }
    }

    public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView, let superview = self.superview else { return }

        self.callPrepareForDismissalWith(view: view)

        if rootView.childViewControllers.contains(view) {
            view.removeFromParentViewController()
        }

        if superview.subviews.contains(view.view) {
            if self.animatedPresentation {
                UIView.animate(withDuration: self.animatedPresentation ? self.animationDuration : 0,
                               animations: { view.view.alpha = 0.0 }) { _ in
                    view.view.removeFromSuperview()
                    completion?()
                }

            } else {
                view.view.removeFromSuperview()
                completion?()
            }
        }
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? SubviewWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(subviewWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? SubviewWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(subviewWireframe: self)
        }
    }
}

extension SubviewWireframe: WireframeProtocol {

}
