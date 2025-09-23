//
//  AppDelegate.swift
//  YouTag
//
//  Created by Youstanzr on 8/12/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
        
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("🚩 App will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("🚩 App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("🚩 App became active")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("🚩 App will terminate")
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
