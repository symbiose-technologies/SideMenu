//
//  UIViewController+Container.swift
//  SideMenu
//
//  Created by kukushi on 2018/8/8.
//  Copyright © 2018 kukushi. All rights reserved.
//

import UIKit

extension UIViewController {

    func load(_ viewController: UIViewController?, on view: UIView, useConstraints: Bool = false) {
        guard let viewController = viewController else {
            return
        }

        // `willMoveToParentViewController:` is called automatically when adding

        addChild(viewController)

        if useConstraints {
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(viewController.view)
            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            // `didMoveToParentViewController:` is called automatically when adding
            viewController.didMove(toParent: self)
            
        } else {
            viewController.view.frame = view.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = true
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            view.addSubview(viewController.view)
            
            viewController.didMove(toParent: self)
            
        }
        
    }

    func unload(_ viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }

        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        // `didMoveToParentViewController:` is called automatically when removing
    }
}
