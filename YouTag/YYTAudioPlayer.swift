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

enum SeekDirection {
    case forward
    case backward
}

class YYTAudioPlayer: NSObject {

    weak var delegate: YYTAudioPlayerDelegate?
    private var avPlayer: AVPlayer?
    private(set) var isSuspended: Bool = false
    var isSongRepeat: Bool = false
    /// Persisted rate to apply when playing
    private var desiredRate: Float = 1.0
    
    // Continuous seek support
    private var seekTimer: Timer?
    private var seekStepSeconds: Float = 10.0
    private var seekRepeatInterval: TimeInterval = 0.5
    // Track continuous seek state (used to avoid auto-advance at end)
    private var isContinuousSeeking: Bool = false
    private var continuousSeekDirection: SeekDirection?
    // Prevent hitting exact end during forward holds (avoid finish event / next track)
    private let endPadding: Double = 0.5
    
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
        print("🎵 Setting up player with song: \(song.title)")
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
                guard let self = self, self.duration() > 0 else { return }
                let currentTime = self.currentTime()
                self.delegate?.audioPlayerPeriodicUpdate(currentTime: currentTime, duration: self.duration())
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
        print("▶️ PLAY called. Suspended: \(isSuspended), rate: \(avPlayer?.rate ?? -1)")
        startPlayback()
    }
    
    func pause() {
        print("⏸️ PAUSE called. Suspended: \(isSuspended), rate before pause: \(avPlayer?.rate ?? -1)")
        if isSuspended {  return  }
        // Keep session alive even when paused
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔄 Audio session kept active during pause")
        } catch {
            print("Failed to keep session active during pause: \(error.localizedDescription)")
        }
        avPlayer?.pause()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
        updateNowPlaying(isPaused: true)
        print("⏸️ AVPlayer paused. rate after pause: \(avPlayer?.rate ?? -1)")
    }

    func next() {
        print("Playing next song")
        PlaylistManager.shared.movePlaylistForward()
        play()
    }

    func prev() {
        if currentTime() > 5 {
            print("Rewind to start of current song")
            seek(to: 0)
        } else {
            print("Playing previous song")
            PlaylistManager.shared.movePlaylistBackward()
            play()
        }
    }
    
    /// Starts or resumes playback at the desired rate and notifies the delegate.
    private func startPlayback() {
        guard !isSuspended else {
            print("⚠️ startPlayback blocked because isSuspended == true")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔄 Ensured audio session is active before playback")
        } catch {
            print("Failed to reactivate session before playback: \(error.localizedDescription)")
        }
        avPlayer?.play()
        avPlayer?.rate = desiredRate
        print("▶️ AVPlayer play() called. New rate: \(avPlayer?.rate ?? -1)")
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

    func currentTime() -> Float {
        guard let secs = avPlayer?.currentTime().seconds, secs.isFinite else { return 0 }
        return Float(secs)
    }

    func duration() -> Float {
        guard let secs = avPlayer?.currentItem?.duration.seconds, secs.isFinite else { return 0 }
        return Float(secs)
    }

    /// Seek by a delta in seconds (positive = forward, negative = backward). Clamped to [0, duration].
    func seek(by seconds: Float) {
        let dur = Double(self.duration())
        guard dur.isFinite && !dur.isNaN && dur > 0 else { return }
        var target = Double(self.currentTime()) + Double(seconds)
        // If we're holding forward, don't cross the track end to avoid finish
        if isContinuousSeeking, continuousSeekDirection == .forward {
            target = min(target, dur - endPadding)
        }
        target = max(0, min(dur, target))
        let time = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.seek(to: time) { [weak self] _ in
            guard let self = self else { return }
            self.updateNowPlaying(isPaused: !(self.avPlayer?.timeControlStatus == .playing))
            self.delegate?.audioPlayerPeriodicUpdate(currentTime: Float(target), duration: self.duration())
        }
    }

    /// Seek to an absolute time in seconds. Clamped to [0, duration].
    func seek(to seconds: Float) {
        let dur = Double(self.duration())
        guard dur.isFinite && !dur.isNaN && dur > 0 else { return }
        var target = Double(seconds)
        if isContinuousSeeking, continuousSeekDirection == .forward {
            target = min(target, dur - endPadding)
        }
        target = max(0, min(dur, target))
        let time = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.seek(to: time) { [weak self] _ in
            guard let self = self else { return }
            self.updateNowPlaying(isPaused: !(self.avPlayer?.timeControlStatus == .playing))
            self.delegate?.audioPlayerPeriodicUpdate(currentTime: Float(target), duration: self.duration())
        }
    }
    
    /// Seek to a percentage of the track (0…1).
    func seek(toPercentage p: Float) {
        let dur = duration()
        guard dur > 0 else { return }
        let clamped = max(0, min(1, p))
        seek(to: clamped * dur)
    }
    
    /// Starts a repeating seek in the given direction until `stopContinuousSeek()` is called.
    /// - Parameters:
    ///   - direction: forward/backward
    ///   - performImmediateTick: if true, perform one seek immediately on begin (good for UI button holds).
    func startContinuousSeek(direction: SeekDirection, performImmediateTick: Bool = true) {
        stopContinuousSeek() // ensure only one timer
        isContinuousSeeking = true
        continuousSeekDirection = direction
        // Optional immediate tick
        if performImmediateTick {
            switch direction {
            case .forward: seek(by: seekStepSeconds)
            case .backward: seek(by: -seekStepSeconds)
            }
        }
        // Repeat while held
        let timer = Timer(timeInterval: seekRepeatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            switch direction {
            case .forward: self.seek(by: self.seekStepSeconds)
            case .backward: self.seek(by: -self.seekStepSeconds)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        seekTimer = timer
    }

    /// Stops any ongoing continuous seeking.
    func stopContinuousSeek() {
        seekTimer?.invalidate()
        seekTimer = nil
        isContinuousSeeking = false
        continuousSeekDirection = nil
    }
    
    func setSongRepeat(to status: Bool) {
        isSongRepeat = status
    }

    func suspend() {
        print("🛑 SUSPEND called")
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

        let maxSize: CGFloat = 512
        let size = image.size
        let scaleRatio = min(1.0, maxSize / max(size.width, size.height))
        let targetSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)

        // Create initial blank artwork
        let blankArtwork = MPMediaItemArtwork(boundsSize: targetSize) { _ in image }

        // Defer heavy rendering to background
        DispatchQueue.global(qos: .userInitiated).async {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let rasterImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            let finalArtwork = MPMediaItemArtwork(boundsSize: rasterImage.size) { _ in rasterImage }
            DispatchQueue.main.async {
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                info[MPMediaItemPropertyArtwork] = finalArtwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
        return blankArtwork
    }

    /// Adds elapsed time and playback rate to nowPlaying info.
    private func applyPlaybackInfo(isPaused: Bool, to info: inout [String: Any]) {
        let dur = Double(self.duration())
        let safeDuration = (dur.isFinite && !dur.isNaN) ? dur : 0
        let rate: Float = isPaused ? 0.0 : Float(avPlayer?.rate ?? 0)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(self.currentTime())
        info[MPMediaItemPropertyPlaybackDuration] = safeDuration
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
    }

    func setupNowPlaying(song: Song) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtwork] = getArtwork(for: song)
        if !song.artists.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyArtist] = song.artists.joined(separator: ", ")
        }
        if let album = song.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }
        if !song.tags.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyGenre] = song.tags.joined(separator: ", ")
        }
        
        // Add looped playlist count and index
        let playlist = PlaylistManager.shared.currentPlaylist
        let count = playlist.count
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = count
        if let idx = playlist.firstIndex(where: { $0.id == song.id }) {
            // Map index to cell row logic: row = (count - 2 - idx) mod count
            let row = ((count - 2 - idx) % count + count) % count
            let trackNumber = row + 1
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = trackNumber
        }
        
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

        // Show Next/Previous instead of +/- skip buttons
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            print("Play command - is playing: \(!self.isPlaying())")
            if !self.isPlaying() {
                self.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            print("Pause command - is playing: \(!self.isPlaying())")
            if self.isPlaying() {
                self.pause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            print("Next track command pressed")
            self.next()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            print("Previous track command pressed")
            self.prev()
            return .success
        }

        // Long-press (seek) support from Command Center / Lock Screen
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.addTarget { [weak self] event in
            guard let self = self, let ev = event as? MPSeekCommandEvent else { return .commandFailed }
            switch ev.type {
            case .beginSeeking:
                self.startContinuousSeek(direction: .forward, performImmediateTick: false)
            case .endSeeking:
                self.stopContinuousSeek()
            @unknown default:
                break
            }
            return .success
        }
        commandCenter.seekBackwardCommand.addTarget { [weak self] event in
            guard let self = self, let ev = event as? MPSeekCommandEvent else { return .commandFailed }
            switch ev.type {
            case .beginSeeking:
                self.startContinuousSeek(direction: .backward, performImmediateTick: false)
            case .endSeeking:
                self.stopContinuousSeek()
            @unknown default:
                break
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            guard let changeEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: Float(changeEvent.positionTime))
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
        print("🔔 handleInterruption: type=\(type), options=\(userInfo[AVAudioSessionInterruptionOptionKey] ?? "none")")
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
        print("🔌 Route change detected: \(String(describing: notification.userInfo))")
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
        print("🔌 handleRouteChange: reason=\(reason.rawValue)")
    }
    
    @objc private func playerDidFinishTrack(_ notification: Notification) {
        // Ignore finish events caused by hitting the end during a hold-seek
        if isContinuousSeeking { return }
        delegate?.audioPlayerDidFinishTrack()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        seekTimer?.invalidate()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }
}
