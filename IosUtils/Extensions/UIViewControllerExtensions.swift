//
//  UIViewControllerExtensions.swift
//  Networkamp
//
//  Created by woko on 27/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation
import UIKit


public extension UIViewController {
    public func embedContainerView(_ controller:UIViewController, containerView:UIView) {
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(controller.view)
        
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        
        controller.didMove(toParentViewController: self)
    }
}
