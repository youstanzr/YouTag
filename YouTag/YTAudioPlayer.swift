//
//  YTAudioPlayer.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/1/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol YTAudioPlayerDelegate: class {
	func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float)
	func audioPlayerPlayingStatusChanged(isPlaying: Bool)
}

class YTAudioPlayer: NSObject, AVAudioPlayerDelegate {
	weak var delegate: YTAudioPlayerDelegate?

	private var playlistManager: PlaylistManager!
	private var audioPlayer: AVAudioPlayer!
	private var songsPlaylist: NSMutableArray!
	private var songDict: Dictionary<String, Any>!
	private var currentSongIndex: Int!
	private var updater = CADisplayLink()
	private var isSuspended: Bool = false
	
	init(playlistManager: PlaylistManager) {
		super.init()
		self.playlistManager = playlistManager
		setupRemoteTransportControls()
		setupInterreuptionsNotifications()
		setupRouteChangeNotifications()
	}
	
	@objc func updateDelegate() {
		delegate?.audioPlayerPeriodicUpdate(currentTime: Float(audioPlayer?.currentTime ?? 0) , duration: Float(audioPlayer?.duration ?? 0))
	}
	
	// MARK: Basics
	/*
	 AVAudioPlayer: An audio player that provides playback of audio data from a file or memory.
	*/
	func setupPlayer(withPlaylist playlist: NSMutableArray) -> Bool {
		songsPlaylist = playlist
		currentSongIndex = 0
		return setupPlayer(withSongAtindex: currentSongIndex)
	}
	
	func setupPlayer(withSongAtindex index: Int) -> Bool{
		return setupPlayer(withSong: songsPlaylist.object(at: currentSongIndex) as! Dictionary<String, Any>)
	}
	
	func setupPlayer(withSong songDict: Dictionary<String, Any>) -> Bool{
		self.songDict = songDict
		let songID = songDict["id"] as? String ?? ""
		let url = LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).m4a")
		do {
			if audioPlayer != nil {
				updater.invalidate()
			}
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer.delegate = self
			audioPlayer.enableRate = true
			audioPlayer.prepareToPlay()
			setupNowPlaying()
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
			updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
			updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
			return true
		} catch {
			print("Error: \(error.localizedDescription)")
			return false
		}
	}
	
	func setPlayerRate(to rate: Float) {
		self.audioPlayer.rate = rate
	}
		
	func setPlayerCurrentTime(withPercentage percenatge: Float) {
		self.audioPlayer.currentTime = TimeInterval(percenatge * Float(self.audioPlayer.duration))
	}
	
	func suspend() {
		pause()
		isSuspended = true
	}

	func unsuspend() {
		isSuspended = false
	}

	func play() {
		if !isSuspended {
			audioPlayer.play()
			updateNowPlaying(isPause: false)
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: true)
		}
	}

	func pause() {
		if !isSuspended && isPlaying() {
			audioPlayer.pause()
			updateNowPlaying(isPause: true)
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
		}
	}
	
	func next() {
		if !isSuspended {
			playlistManager.movePlaylistForward()
			currentSongIndex = currentSongIndex % songsPlaylist.count
			if setupPlayer(withSongAtindex: currentSongIndex) {
				play()
			}
		}
	}
	
	func prev() {
		if !isSuspended {
			playlistManager.movePlaylistBackward()
			currentSongIndex = currentSongIndex % songsPlaylist.count
			if setupPlayer(withSongAtindex: currentSongIndex) {
				play()
			}
		}
	}

	func isPlaying() -> Bool {
		return audioPlayer?.isPlaying ?? false
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
			let e = event as? MPChangePlaybackPositionCommandEvent
			self.audioPlayer.currentTime = e!.positionTime
			return .success
		}
	}

	func setupNowPlaying() {
		// Define Now Playing Info
		var nowPlayingInfo = [String : Any]()
		nowPlayingInfo[MPMediaItemPropertyTitle] = songDict["title"] as? String

		let songID = songDict["id"] as? String ?? ""
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).jpg"))
		if let image = UIImage(data: imageData ?? Data()) {
			nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
				return image
			}
		}
		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
		nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
		nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
		
		// Set the metadata
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}

	func updateNowPlaying(isPause: Bool) {
		// Define Now Playing Info
		var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
		
		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
		nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = !isPause
		
		// Set the metadata
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}
	
	// MARK: Handle Finish Playing
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("Audio player did finish playing: \(flag)")
		if (flag) {
			next()
		}
	}
	
	// MARK: Handle Interruptions
	/*
	When you are playing in background mode, if a phone call come then the sound will be muted but when hang off the phone call then the sound does not automatically continue playing.
	*/
	func setupInterreuptionsNotifications() {
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self,
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
		#warning("This interruption end handling is not working when phone call hang off")
		if type == .began {
			print("Interruption began")
			// Interruption began, take appropriate actions
		}
		else if type == .ended {
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
				print(options)
				if options.contains(.shouldResume) {
					// Interruption Ended - playback should resume
					print("Interruption Ended - playback should resume")
					self.play()
				} else {
					// Interruption Ended - playback should NOT resume
					print("Interruption Ended - playback should NOT resume")
				}
			}
		}
	}
	
	// MARK: Handle Route Changes
	/*
	when you plug a headphone into the phone then the sound will emit on the headphone. But when you unplug the headphone then the sound automatically continue playing on built-in speaker. Maybe this is the behavior that you don’t expect. B/c when you plug the headphone into you want the sound is private to you, and when you unplug it you don’t want it emit out to other people. We will handle it by receiving events when the route change
	*/
	func setupRouteChangeNotifications() {
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self,
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
					DispatchQueue.main.sync {
						self.play()
					}
					break
				}
			case .oldDeviceUnavailable:
				if let previousRoute =
					userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
					for output in previousRoute.outputs where
						(output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.bluetoothA2DP) {
						print("headphones disconnected")
						DispatchQueue.main.sync {
							self.pause()
						}
						break
					}
				}
			default: ()
		}
	}
}
