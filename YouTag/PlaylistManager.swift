//
//  PlaylistManager.swift
//  YouTag
//
//  Created by Youstanzr on 3/19/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class PlaylistManager: NSObject, PlaylistLibraryViewDelegate, NowPlayingViewDelegate {
	
	var nowPlayingView: NowPlayingView!
	var playlistLibraryView: PlaylistLibraryView!
	var audioPlayer: YYTAudioPlayer!
	var playlistFilters = PlaylistFilters(tags: [], artists: [], album: [], releaseYearRange: [], releaseYear: [], duration: [])
	
	override init() {
		super.init()
		audioPlayer = YYTAudioPlayer(playlistManager: self)
		playlistLibraryView = PlaylistLibraryView()
		playlistLibraryView.PLDelegate = self
		nowPlayingView = NowPlayingView(frame: .zero, audioPlayer: audioPlayer)
		nowPlayingView.NPDelegate = self
		refreshNowPlayingView()
	}
				
	func updatePlaylistLibrary(toPlaylist newPlaylist: NSMutableArray) {
		playlistLibraryView.playlistArray = newPlaylist
		playlistLibraryView.refreshTableView()
		refreshNowPlayingView()
	}
	
	func refreshNowPlayingView() {
		let songDict: Dictionary<String, Any>
		if playlistLibraryView.playlistArray.count > 0 {
			audioPlayer.unsuspend()
			songDict = playlistLibraryView.playlistArray.object(at: playlistLibraryView.playlistArray.count-1) as! Dictionary<String, Any>
		} else {
			audioPlayer.suspend()
			songDict = Dictionary<String, Any>()
		}

		let songID = songDict["id"] as? String ?? ""
		nowPlayingView.songID = songID
		nowPlayingView.titleLabel.text = songDict["title"] as? String ?? ""
		nowPlayingView.artistLabel.text = ((songDict["artists"] as? NSArray ?? NSArray())!.componentsJoined(by: ", "))
		
		nowPlayingView.titleLabel.restartLabel()
		if nowPlayingView.titleLabel.text!.isRTL {
			nowPlayingView.titleLabel.type = .continuousReverse
		} else {
			nowPlayingView.titleLabel.type = .continuous
		}

		nowPlayingView.artistLabel.restartLabel()
		if nowPlayingView.artistLabel.text!.isRTL {
			nowPlayingView.artistLabel.type = .continuousReverse
		} else {
			nowPlayingView.artistLabel.type = .continuous
		}
		
		nowPlayingView.lyricsTextView.text = songDict["lyrics"] as? String
		let isLyricsAvailable = nowPlayingView.lyricsTextView.text != ""
		nowPlayingView.lyricsTextView.isHidden = !isLyricsAvailable
		nowPlayingView.lyricsButton.isHidden = isLyricsAvailable
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).jpg"))
		if let imgData = imageData {
			nowPlayingView.thumbnailImageView.image = UIImage(data: imgData)
		} else {
			nowPlayingView.thumbnailImageView.image = UIImage(named: "placeholder")
		}

		let oldPlaybackRate = audioPlayer.getPlayerRate()
		
		if playlistLibraryView.playlistArray.count > 0 {
			_ = audioPlayer.setupPlayer(withPlaylist: NSMutableArray(array: playlistLibraryView.playlistArray.reversed()))
		}

		nowPlayingView.playbackRateButton.titleLabel?.text = "x\(oldPlaybackRate == 1.0 ? 1 : oldPlaybackRate)"
		nowPlayingView.progressBar.value = 0.0
		nowPlayingView.currentTimeLabel.text = "00:00"
		nowPlayingView.timeLeftLabel.text = (songDict["duration"] as? String) ?? "00:00"
	}
	
	func refreshPlaylistLibraryView() {
		playlistLibraryView.refreshTableView()
		refreshNowPlayingView()
	}
	
	func movePlaylistForward() {
		playlistLibraryView.playlistArray.insert(playlistLibraryView.playlistArray.lastObject!, at: 0)
		playlistLibraryView.playlistArray.removeObject(at: playlistLibraryView.playlistArray.count - 1)
		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func movePlaylistBackward() {
		playlistLibraryView.playlistArray.add(playlistLibraryView.playlistArray.object(at: 0))
		playlistLibraryView.playlistArray.removeObject(at: 0)
		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func didSelectSong(songDict: Dictionary<String, Any>) {
		refreshNowPlayingView()
		nowPlayingView.pausePlayButtonAction(sender: nil)
	}
	
	func shufflePlaylist() {
		if playlistLibraryView.playlistArray.count <= 1 {
			return
		}
		let lastObject = playlistLibraryView.playlistArray.object(at: playlistLibraryView.playlistArray.count - 1)
		let whatsNextArr = playlistLibraryView.playlistArray
		whatsNextArr.removeLastObject()
		let shuffledArr = NSMutableArray(array: whatsNextArr.shuffled())
		shuffledArr.add(lastObject)
		playlistLibraryView.playlistArray = shuffledArr
		playlistLibraryView.refreshTableView()
	}

	// MARK: Filter processing functions
	func computePlaylist() {
		var newPlaylist = LibraryManager.getLibraryArray()
		newPlaylist = applyTagFilter(on: newPlaylist)
		newPlaylist = applyArtistFilter(on: newPlaylist)
		newPlaylist = applyAlbumFilter(on: newPlaylist)
		newPlaylist = applyReleaseYearFilter(on: newPlaylist)
		newPlaylist = applyReleaseYearRangeFilter(on: newPlaylist)
		newPlaylist = applyDurationFilter(on: newPlaylist)

		updatePlaylistLibrary(toPlaylist: newPlaylist)
	}
	
	func applyTagFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.tags.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songTags: NSMutableArray
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songTags = NSMutableArray(array: songDict["tags"] as? NSArray ?? NSArray())
			if playlistFilters.tags.hasIntersect(with: songTags) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}

	func applyArtistFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.artists.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songArtists: NSMutableArray
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songArtists = NSMutableArray(array: songDict["artists"] as? NSArray ?? NSArray())
			if playlistFilters.artists.hasIntersect(with: songArtists) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}

	func applyAlbumFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.album.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songAlbum: String
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songAlbum = songDict["album"] as? String ?? ""
			if playlistFilters.album.contains(songAlbum) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}
	
	func applyReleaseYearFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.releaseYear.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songReleaseYear: String
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songReleaseYear = songDict["releaseYear"] as? String ?? ""
			if playlistFilters.releaseYear.contains(songReleaseYear) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}

	func applyReleaseYearRangeFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.releaseYearRange.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songReleaseYear: Int
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songReleaseYear = Int(songDict["releaseYear"] as? String ?? "-1") ?? -1
			if isValue(Double(songReleaseYear), inBoundList: playlistFilters.releaseYearRange) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}

	
	func applyDurationFilter(on playlist: NSMutableArray) -> NSMutableArray {
		if playlistFilters.duration.count == 0 {
			return playlist
		}
		var songDict: Dictionary<String, Any>
		var songDuration: TimeInterval
		let newPlaylist = NSMutableArray()
		for i in 0 ..< playlist.count {
			songDict = playlist.object(at: i) as! Dictionary<String, Any>
			songDuration = (songDict["duration"] as! String).convertToTimeInterval()
			if isValue(songDuration, inBoundList: playlistFilters.duration) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}
	
	fileprivate func isValue(_ val: Double, inBoundList durationList: NSMutableArray) -> Bool {
		var durationBound: NSMutableArray
		var lowerBound: Double
		var upperBound: Double
		for j in 0 ..< durationList.count {
			durationBound = durationList.object(at: j) as! NSMutableArray
			lowerBound = durationBound.object(at: 0) as! Double
			upperBound = durationBound.object(at: 1) as! Double
			if val < lowerBound || val > upperBound {
				return false
			}
		}
		return true
	}
			
}
