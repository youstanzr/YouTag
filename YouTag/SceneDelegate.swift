//
//  SceneDelegate.swift
//  YouTag
//
//  Created by Yousef AlQattan on 2025-09-23.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        // If you want a nav stack, wrap it:
        // let root = UINavigationController(rootViewController: ViewController())
        let root = ViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene did become active")
    }
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene did enter background")
    }
}
