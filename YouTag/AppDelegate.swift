//
//  AppDelegate.swift
//  YouTag
//
//  Created by Youstanzr on 8/12/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

import UIKit
import AVFoundation
import SQLite3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /*
         To allow the sound continue playing in background mode
         AVAudioSession: An intermediary object that communicates to the system how you intend to use audio in your app.
         */
        configureAudioSession()

        // Observe audio session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // Prepare App Data
        LibraryManager.shared.setupDatabase()
        LocalFilesManager.ensureImagesDirectoryExists()
        LocalFilesManager.getSongsDirectoryURL()
        LibraryManager.shared.recomputeSongDurationsBlocking()
        
        // Add session state observer
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.silenceSecondaryAudioHintNotification,
            object: nil,
            queue: .main
        ) { note in
            print("🔇 Secondary audio hint: \(note.userInfo ?? [:])")
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { note in
            print("🔌 Route change (AppDelegate): \(note.userInfo ?? [:])")
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereLostNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🛑 Media services were lost")
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("♻️ Media services were reset")
        }
        
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
        print("🚩 App entered background - reactivating audio session")
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to keep audio session active: \(error.localizedDescription)")
        }
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
    
    
    // MARK: - Configure Audio
    
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
            
    // MARK: - Audio Session Interruption Handling

    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            print("Audio session interruption began.")
        } else if type == .ended {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("Audio session interruption ended. Audio session reactivated.")
            } catch {
                print("Failed to reactivate audio session: \(error.localizedDescription)")
            }
        }
    }
    
}
