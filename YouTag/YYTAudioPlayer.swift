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

protocol YYTAudioPlayerDelegate: class {
	func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float)
	func audioPlayerPlayingStatusChanged(isPlaying: Bool)
}

class YYTAudioPlayer: NSObject, AVAudioPlayerDelegate {

	weak var delegate: YYTAudioPlayerDelegate?

	private var playlistManager: PlaylistManager!
	private var audioPlayer: AVAudioPlayer!
	private var songsPlaylist: NSMutableArray!
	private var songDict: Dictionary<String, Any>!
	private var currentSongIndex: Int!
	private var updater = CADisplayLink()
	private(set) var isSuspended: Bool = false
	var isSongRepeat: Bool = false
	
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
	
	func setupPlayer(withSongAtindex index: Int) -> Bool {
		return setupPlayer(withSong: songsPlaylist.object(at: currentSongIndex) as! Dictionary<String, Any>)
	}
	
	func setupPlayer(withSong songDict: Dictionary<String, Any>) -> Bool {
		self.songDict = songDict
		let songID = songDict["id"] as! String
		let songExt = songDict["fileExtension"] as? String ?? "m4a"  //support legacy code
		let url = LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).\(songExt)")
		do {
			if audioPlayer != nil {
				updater.invalidate()
			}
			let oldPlaybackRate = getPlayerRate()
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer.delegate = self
			audioPlayer.enableRate = true
			audioPlayer.prepareToPlay()
			setupNowPlaying()
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
			setPlayerRate(to: oldPlaybackRate)
			updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
			return true
		} catch {
			print("Error: \(error.localizedDescription)")
			return false
		}
	}
	
	func setPlayerRate(to rate: Float) {
		audioPlayer.rate = rate
		updateNowPlaying(isPause: isPlaying())
	}

	func getPlayerRate() -> Float {
		return audioPlayer?.rate ?? 1.0
	}

	func setPlayerCurrentTime(withPercentage percenatge: Float) {
		if audioPlayer == nil {
			return
		}
		audioPlayer.currentTime = TimeInterval(percenatge * Float(audioPlayer.duration))
		updateNowPlaying(isPause: isPlaying())
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

	func play() {
		if !isSuspended {
			audioPlayer.play()
			updateNowPlaying(isPause: false)
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: true)
			updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
			updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
		}
	}

	func pause() {
		if !isSuspended && isPlaying() {
			audioPlayer.pause()
			updateNowPlaying(isPause: true)
			delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
			updater.invalidate()
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
			if Float(audioPlayer?.currentTime ?? 0) < 10.0 {
				playlistManager.movePlaylistBackward()
				currentSongIndex = currentSongIndex % songsPlaylist.count
				if setupPlayer(withSongAtindex: currentSongIndex) {
					play()
				}
			} else {
				self.audioPlayer.currentTime = 0.0
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
		let image: UIImage
		if let imgData = imageData {
			image = UIImage(data: imgData)!
		} else {
			image = UIImage(named: "placeholder")!
		}
		
		nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
			return image
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
		nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = !isPause ? audioPlayer.rate : 0.0
		
		// Set the metadata
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}
	
	// MARK: Handle Finish Playing
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("Audio player did finish playing: \(flag)")
		if (flag) {
			if (isSongRepeat) {
				play()
			} else {
				next()
			}
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
					DispatchQueue.main.sync {
						play()
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
							pause()
						}
						break
					}
				}
			default: ()
		}
	}
	
}
