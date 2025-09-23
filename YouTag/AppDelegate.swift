//
//  AppDelegate.swift
//  YouTag
//
//  Created by Youstanzr on 8/12/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        configureAudioSessionCategory()

        // App data bootstrap
        LibraryManager.shared.setupDatabase()
        LocalFilesManager.ensureImagesDirectoryExists()
        LocalFilesManager.getSongsDirectoryURL()
                
        // Entitlements: fast cached state, then real scan
        SubscriptionManager.shared.bootstrapEntitlementFromCache()
        Task { await SubscriptionManager.shared.updateEntitlementStatus() }
        SubscriptionManager.shared.startTransactionListener()

        return true
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // Release any resources specific to discarded scenes here.
        print("Discarded scene sessions: \(sceneSessions)")
    }
    
    
    // MARK: - Audio session
    private func configureAudioSessionCategory() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(.playback)
        } catch {
            let e = error as NSError
            print("AudioSession error: \(e.domain) code=\(e.code) \(e.localizedDescription)")
        }
    }
}
