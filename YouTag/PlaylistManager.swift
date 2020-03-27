//
//  PlaylistManager.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/19/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class PlaylistManager: NSObject, PlaylistLibraryViewDelegate {
	
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
		refreshNowPlayingView()
	}
				
	func updatePlaylistLibrary(toPlaylist newPlaylist: NSMutableArray) {
		playlistLibraryView.playlistArray = newPlaylist
		playlistLibraryView.refreshTableView()
	}
	
	func refreshNowPlayingView() {
		let songDict: Dictionary<String, Any>
		if playlistLibraryView.playlistArray.count > 0 {
			audioPlayer.unsuspend()
			songDict = playlistLibraryView.playlistArray.object(at: 0) as! Dictionary<String, Any>
		} else {
			audioPlayer.suspend()
			songDict = Dictionary<String, Any>()
		}

		let songID = songDict["id"] as? String ?? ""
		nowPlayingView.titleLabel.text = songDict["title"] as? String
		nowPlayingView.artistLabel.text = (songDict["artists"] as? NSArray ?? NSArray())!.componentsJoined(by: ", ")
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).jpg"))
		nowPlayingView.thumbnailImageView.image = UIImage(data: imageData ?? Data())
		
		if playlistLibraryView.playlistArray.count > 0 {
			_ = audioPlayer.setupPlayer(withPlaylist: playlistLibraryView.playlistArray)
		}
	}
	
	func refreshPlaylistLibraryView() {
		playlistLibraryView.refreshTableView()
		refreshNowPlayingView()
	}
	
	func movePlaylistForward() {
		playlistLibraryView.playlistArray.add(playlistLibraryView.playlistArray.object(at: 0))
		playlistLibraryView.playlistArray.removeObject(at: 0)
		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func movePlaylistBackward() {
		playlistLibraryView.playlistArray.insert(playlistLibraryView.playlistArray.lastObject!, at: 0)
		playlistLibraryView.playlistArray.removeObject(at: playlistLibraryView.playlistArray.count - 1)
		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func didSelectSong(songDict: Dictionary<String, Any>) {
		refreshNowPlayingView()
		nowPlayingView.pausePlayButtonAction(sender: nil)
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
		refreshNowPlayingView()
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
			if playlistFilters.tags.isSubset(of: songTags) {
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
