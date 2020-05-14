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
				
	func updatePlaylistLibrary(toPlaylist newPlaylist: [Song]) {
		playlistLibraryView.playlistArray = newPlaylist
		playlistLibraryView.refreshTableView()
		refreshNowPlayingView()
	}
	
	func refreshNowPlayingView() {
		let song: Song
		if playlistLibraryView.playlistArray.count > 0 {
			audioPlayer.unsuspend()
            song = playlistLibraryView.playlistArray[playlistLibraryView.playlistArray.count - 1]
			
		} else {
			audioPlayer.suspend()
            song = .emptySong
		}

        let songID = song.id
		nowPlayingView.songID = songID
        nowPlayingView.titleLabel.text = song.title
        nowPlayingView.artistLabel.text = song.artistsJoined
		
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
		
        nowPlayingView.lyricsTextView.text = song.lyrics
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
        nowPlayingView.timeLeftLabel.text = (song.duration.isEmpty) ? "00:00" : song.duration
	}
	
	func refreshPlaylistLibraryView() {
		playlistLibraryView.refreshTableView()
		refreshNowPlayingView()
	}
	
	func movePlaylistForward() {
        guard let last = playlistLibraryView.playlistArray.last else {
            return
        }
        playlistLibraryView.playlistArray.insert(last, at: 0)
        playlistLibraryView.playlistArray.remove(at: playlistLibraryView.playlistArray.count - 1)

		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func movePlaylistBackward() {
        // need to test
        guard let first = playlistLibraryView.playlistArray.first else { return }
        playlistLibraryView.playlistArray.append(first)
        playlistLibraryView.playlistArray.removeFirst()
		playlistLibraryView.reloadData()
		refreshNowPlayingView()
	}
	
	func didSelectSong(song: Song) {
		refreshNowPlayingView()
		nowPlayingView.pausePlayButtonAction(sender: nil)
	}
	
	func shufflePlaylist() {
		if playlistLibraryView.playlistArray.count <= 1 {
			return
		}
        guard let last = playlistLibraryView.playlistArray.last else { return }
		var whatsNextArr = playlistLibraryView.playlistArray
        whatsNextArr.removeLast()
        var shuffledArr = whatsNextArr.shuffled()
		shuffledArr.append(last)
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
	
	func applyTagFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.tags.count == 0 {
			return playlist
		}
		var songDict: Song
		var songTags: NSMutableArray
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songTags = NSMutableArray(array: songDict.tags as NSArray)
			if playlistFilters.tags.isSubset(of: songTags) {
				newPlaylist.append(songDict)
			}
		}
		return newPlaylist
	}

	func applyArtistFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.artists.count == 0 {
			return playlist
		}
		var songDict: Song
		var songArtists: NSMutableArray
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songArtists = NSMutableArray(array: songDict.artists as NSArray)
			if playlistFilters.artists.hasIntersect(with: songArtists) {
				newPlaylist.append(songDict)
			}
		}
		return newPlaylist
	}

	func applyAlbumFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.album.count == 0 {
			return playlist
		}
		var songDict: Song
		var songAlbum: String
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songAlbum = songDict.album ?? ""
			if playlistFilters.album.contains(songAlbum) {
				newPlaylist.append(songDict)
			}
		}
		return newPlaylist
	}
	
	func applyReleaseYearFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.releaseYear.count == 0 {
			return playlist
		}
		var songDict: Song
		var songReleaseYear: String
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songReleaseYear = songDict.releaseYear
			if playlistFilters.releaseYear.contains(songReleaseYear) {
				newPlaylist.append(songDict)
			}
		}
		return newPlaylist
	}

	func applyReleaseYearRangeFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.releaseYearRange.count == 0 {
			return playlist
		}
		var songDict: Song
		var songReleaseYear: Int
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songReleaseYear = Int(songDict.releaseYear) ?? -1
			if isValue(Double(songReleaseYear), inBoundList: playlistFilters.releaseYearRange) {
				newPlaylist.append(songDict)
			}
		}
		return newPlaylist
	}

	
	func applyDurationFilter(on playlist: [Song]) -> [Song] {
		if playlistFilters.duration.count == 0 {
			return playlist
		}
		var songDict: Song
		var songDuration: TimeInterval
        var newPlaylist: [Song] = []
		for i in 0 ..< playlist.count {
			songDict = playlist[i]
            songDuration = songDict.duration.convertToTimeInterval()
			if isValue(songDuration, inBoundList: playlistFilters.duration) {
				newPlaylist.append(songDict)
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
