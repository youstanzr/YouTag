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
	var audioPlayer: YTAudioPlayer!

	override init() {
		super.init()
		audioPlayer = YTAudioPlayer(playlistManager: self)
		playlistLibraryView = PlaylistLibraryView()
		playlistLibraryView.PLDelegate = self
		nowPlayingView = NowPlayingView(frame: .zero, audioPlayer: audioPlayer)
		refreshNowPlayingView()
	}
	
	func updateTagsList(to newTagsList: NSMutableArray) {
		let newPlaylist = computePlaylist(fromTags: newTagsList)
		updatePlaylistLibrary(toPlaylist: newPlaylist)
		refreshNowPlayingView()
	}
		
	func computePlaylist(fromTags newTagsList: NSMutableArray) -> NSMutableArray{
		let libraryArray = LibraryManager.getLibraryArray()
		let newPlaylist = NSMutableArray()
		var songDict = Dictionary<String, Any>()
		var songTags = NSMutableArray()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			songTags = NSMutableArray(array: songDict["tags"] as? NSArray ?? NSArray())
			if newTagsList.isSubset(arr: songTags) {
				newPlaylist.add(songDict)
			}
		}
		return newPlaylist
	}
	
	func updatePlaylistLibrary(toPlaylist newPlaylist: NSMutableArray) {
		playlistLibraryView.playlistArray = newPlaylist
		playlistLibraryView.refreshTableView()
	}
	
	func refreshNowPlayingView() {
		let songDict: Dictionary<String, Any>
		if playlistLibraryView.playlistArray.count > 0 {
			audioPlayer.unsuspend()
			songDict = playlistLibraryView.playlistArray.object(at: 0) as! Dictionary<String, AnyObject>
		} else {
			audioPlayer.suspend()
			songDict = Dictionary<String, AnyObject>()
		}

		let songID = songDict["id"] as? String ?? ""
		nowPlayingView.titleLabel.text = songDict["title"] as? String
		nowPlayingView.artistLabel.text = (songDict["artists"] as? NSArray)!.componentsJoined(by: ", ")
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
}
