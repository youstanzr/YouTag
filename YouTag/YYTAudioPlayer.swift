//
//  YYTAudioPlayer.swift
//  YouTag
//
//  Created by Youstanzr on 3/1/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol YYTAudioPlayerDelegate: AnyObject {
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float)
    func audioPlayerPlayingStatusChanged(isPlaying: Bool)
    func audioPlayerDidFinishTrack()
}

class YYTAudioPlayer: NSObject {

    weak var delegate: YYTAudioPlayerDelegate?
    private var avPlayer: AVPlayer?
    private(set) var isSuspended: Bool = false
    var isSongRepeat: Bool = false
    /// Persisted rate to apply when playing
    private var desiredRate: Float = 1.0
    
    override init() {
        super.init()
        setupRemoteTransportControls()
        setupInterreuptionsNotifications()
        setupRouteChangeNotifications()
    }
    
    
    // MARK: - Setup Player
    /*
     AVAudioPlayer: An audio player that provides playback of audio data from a file or memory.
    */
    func setupPlayer() -> Bool {
        return setupPlayer(withSongAtIndex: 0)
    }

    func setupPlayer(withSongAtIndex index: Int) -> Bool {
        guard index < PlaylistManager.shared.currentPlaylist.count else {
            print("Invalid song index: \(index)")
            return false
        }
        let song = PlaylistManager.shared.currentPlaylist[index]
        return setupPlayer(withSong: song)
    }

    func setupPlayer(withSong song: Song) -> Bool {
        unsuspend()
        
        // Stop any previous playback
        avPlayer?.pause()
        avPlayer = nil

        guard let url = LibraryManager.shared.urlForSong(song) else {
            print("Invalid song data: Could not resolve file URL for song \(song.id)")
            return false
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Invalid song data: File does not exist at \(url.path).")
            return false
        }
        avPlayer = AVPlayer(url: url)
        setupNowPlaying(song: song)
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
        if let avp = avPlayer {
            avp.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 2), queue: .main) { [weak self] time in
                guard let self = self, let item = avp.currentItem, item.duration.seconds.isFinite else { return }
                let currentTime = Float(time.seconds)
                self.delegate?.audioPlayerPeriodicUpdate(currentTime: currentTime, duration: self.duration())
                // Update Control Center progress
                self.updateNowPlaying(isPaused: !(avp.rate != 0 && avp.timeControlStatus == .playing))
            }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishTrack(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: avp.currentItem
            )
        }
        return true
    }
    
    // MARK: - Playback Controls
    func play(song: Song) -> Bool {
        guard setupPlayer(withSong: song) else { return false }
        startPlayback()
        return true
    }

    func play() {
        startPlayback()
    }
    
    func pause() {
        if isSuspended {  return  }
        avPlayer?.pause()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
        updateNowPlaying(isPaused: true)
    }

    func next() {
        PlaylistManager.shared.movePlaylistForward()
        play()
    }

    func prev() {
        PlaylistManager.shared.movePlaylistBackward()
        play()
    }
    
    /// Starts or resumes playback at the desired rate and notifies the delegate.
    private func startPlayback() {
        guard !isSuspended else { return }
        avPlayer?.play()
        avPlayer?.rate = desiredRate
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: true)
        updateNowPlaying(isPaused: false)
    }

    func clearPlayback() {
        // 1. Pause any ongoing playback
        avPlayer?.pause()
        suspend()
        
        // 2. Unregister our end‐of‐track observer
        if let currentItem = avPlayer?.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: currentItem
            )
        }
        
        // 3. Remove the item from the player and release it
        avPlayer?.replaceCurrentItem(with: nil)
        avPlayer = nil
        
        // 4. Inform delegate/UI that playback has stopped
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
    }

    func isPlaying() -> Bool {
        if let avp = avPlayer {
            return avp.rate != 0 && avp.timeControlStatus == .playing
        }
        return false
    }

    func setPlaybackRate(to rate: Float) {
        desiredRate = rate
        // Only adjust the active player if it's already playing
        if let avp = avPlayer, avp.timeControlStatus == .playing {
            avp.rate = rate
        }
    }
    
    func duration() -> Float {
        guard let secs = avPlayer?.currentItem?.duration.seconds, secs.isFinite else { return 0 }
        return Float(secs)
    }

    func setCurrentTime(to percentage: Float) {
        if let avp = avPlayer, let item = avp.currentItem {
            let duration = item.duration.seconds
            if duration.isFinite && !duration.isNaN {
                let seconds = Double(percentage) * duration
                let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                avp.seek(to: time)
            }
        }
        updateNowPlaying(isPaused: !isPlaying())
    }
    
    func setSongRepeat(to status: Bool) {
        isSongRepeat = status
    }

    func suspend() {
        pause()
        isSuspended = true
    }

    func unsuspend() {
        isSuspended = false
    }


    // MARK: - Now Playing Info

    /// Returns the appropriate artwork for a song.
    private func getArtwork(for song: Song) -> MPMediaItemArtwork {
        // Fetch custom thumbnail or fallback to placeholder
        let image = LibraryManager.shared.fetchThumbnail(for: song)
            ?? UIImage(named: "placeholder", in: Bundle.main, compatibleWith: nil)
            ?? UIImage()
        // Rasterize image for compatibility
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let rasterImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return MPMediaItemArtwork(boundsSize: rasterImage.size) { _ in rasterImage }
    }

    /// Adds elapsed time and playback rate to nowPlaying info.
    private func applyPlaybackInfo(isPaused: Bool, to info: inout [String: Any]) {
        let elapsed = avPlayer?.currentItem?.currentTime().seconds ?? 0
        let duration = avPlayer?.currentItem?.duration.seconds.isFinite == true
            ? avPlayer!.currentItem!.duration.seconds
            : 0
        let rate: Float = isPaused ? 0.0 : Float(avPlayer?.rate ?? 0)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
    }

    func setupNowPlaying(song: Song) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtwork] = getArtwork(for: song)
        // Add elapsed time, rate, and duration
        let isPaused = !(avPlayer?.rate != 0 && avPlayer?.timeControlStatus == .playing)
        applyPlaybackInfo(isPaused: isPaused, to: &nowPlayingInfo)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func updateNowPlaying(isPaused: Bool) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        applyPlaybackInfo(isPaused: isPaused, to: &nowPlayingInfo)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    
            
    // MARK: Control from Control Center
    /*
    Support controlling background audio from the Control Center and iOS Lock screen.
    */
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            print("Play command - is playing: \(!self.isPlaying())")
            if !self.isPlaying() {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("Pause command - is playing: \(!self.isPlaying())")
            if self.isPlaying() {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            print("Next track command pressed")
            self.next()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            print("Previous track command pressed")
            self.prev()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            guard let changeEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let seekTime = CMTime(seconds: changeEvent.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            self.avPlayer?.seek(to: seekTime) { _ in
                self.updateNowPlaying(isPaused: !(self.avPlayer?.timeControlStatus == .playing))
            }
            return .success
        }
    }
        
    // MARK: Handle Interruptions
    /*
    When you are playing in background mode, if a phone call come then the sound will be muted but when hang off the phone call then the sound should automatically continue playing.
    */
    func setupInterreuptionsNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            print("Interruption began")
            // Interruption began, take appropriate actions
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                    print("Interruption Ended - playback should resume")
                    play()
                } else {
                    // Interruption Ended - playback should NOT resume
                    print("Interruption Ended - playback should NOT resume")
                    pause()
                }
            }
        }
    }
    
    // MARK: Handle Route Changes
    /*
    when you plug a headphone into the phone then the sound will emit on the headphone. But when you unplug the headphone then the sound automatically continue playing on built-in speaker. Maybe this is the behavior that you don’t expect. B/c when you plug the headphone into you want the sound is private to you, and when you unplug it you don’t want it emit out to other people. We will handle it by receiving events when the route change
    */
    func setupRouteChangeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        print("handleRouteChange")
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }

        switch reason {
            case .newDeviceAvailable:
                let session = AVAudioSession.sharedInstance()
                for output in session.currentRoute.outputs where
                    (output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.bluetoothA2DP) {
                    print("headphones connected")
                    DispatchQueue.main.async { [weak self] in
                        self?.play()
                    }
                    break
                }
            case .oldDeviceUnavailable:
                if let previousRoute =
                    userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                    for output in previousRoute.outputs where
                        (output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.bluetoothA2DP) {
                        print("headphones disconnected")
                        DispatchQueue.main.async { [weak self] in
                            self?.pause()
                        }
                        break
                    }
                }
            default: ()
        }
    }
    
    @objc private func playerDidFinishTrack(_ notification: Notification) {
        delegate?.audioPlayerDidFinishTrack()
    }
    
}
