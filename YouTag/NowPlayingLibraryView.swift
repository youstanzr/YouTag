//
//  NowPlayingLibraryView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/29/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class NowPlayingLibraryView: LibraryTableView {
	var playlistArray = NSMutableArray()
	var tagsList = NSMutableArray()
	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		playlistArray = LM.libraryArray
    }
	
	func updateTagsList(to newTagsList: NSMutableArray) {
		self.tagsList = newTagsList
		self.refreshTableView()
	}
    
	override func refreshTableView() {
		self.LM.refreshLibraryArray()
		playlistArray.removeAllObjects()
		var songDict = Dictionary<String, Any>()
		var songTags = NSMutableArray()
		for i in 0 ..< LM.libraryArray.count {
			songDict = LM.libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			songTags = NSMutableArray(array: songDict["songTags"] as? NSArray ?? NSArray())
			if tagsList.isSubset(arr: songTags) {
				playlistArray.add(songDict)
			}
		}
		let currentController = self.getCurrentViewController() as? ViewController
		if playlistArray.count > 0 {
			songDict = playlistArray.object(at: 0) as! Dictionary<String, AnyObject>
			currentController?.nowPlayingView.updateSongDict(to: songDict)
		} else {
			currentController?.nowPlayingView.updateSongDict(to: Dictionary<String, Any>())
		}
		self.reloadData()
	}
	
	func movePlaylistForward() {
		playlistArray.add(playlistArray.object(at: 0))
		playlistArray.removeObject(at: 0)
		self.reloadData()
		let songDict = playlistArray.object(at: 0) as! Dictionary<String, AnyObject>
		let currentController = self.getCurrentViewController() as? ViewController
		currentController?.nowPlayingView.songDict = songDict
		currentController?.nowPlayingView.refreshView()
	}
	
	func movePlaylistBackward() {
		playlistArray.insert(playlistArray.lastObject!, at: 0)
		playlistArray.removeObject(at: playlistArray.count - 1)
		self.reloadData()
		let songDict = playlistArray.object(at: 0) as! Dictionary<String, AnyObject>
		let currentController = self.getCurrentViewController() as? ViewController
		currentController?.nowPlayingView.songDict = songDict
		currentController?.nowPlayingView.refreshView()
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return playlistArray.count-1
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath as IndexPath) as! LibraryCell
		cell.backgroundColor = UIColor.clear
		let songDict = playlistArray.object(at: (indexPath.row+1) % playlistArray.count) as! Dictionary<String, Any>
		cell.songID = songDict["songID"] as! String
		cell.titleLabel.text = songDict["songTitle"] as? String
		cell.artistLabel.text = songDict["artistName"] as? String
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(cell.songID).jpg"))
		cell.thumbnailImageView.image = UIImage(data: imageData ?? Data())
		cell.durationLabel.text = songDict["duration"] as? String
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as! LibraryCell
		#warning("Can change the cell to have the song dict so we remove the getSong by id func call")
		let songDict = LM.getSong(forID: cell.songID)
		print("Selected cell number \(indexPath.row) -> \(songDict["songTitle"] ?? "")")

		playlistArray.remove(songDict)
		playlistArray.insert(songDict, at: 0)
		
		tableView.deselectRow(at: indexPath, animated: false)
		tableView.reloadData()
		
		let currentController = self.getCurrentViewController() as! ViewController
		currentController.nowPlayingView.songDict = songDict
		currentController.nowPlayingView.refreshView()
		currentController.nowPlayingView.pausePlayButtonAction(sender: nil)
    }
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			playlistArray.removeObject(at: indexPath.row+1 % playlistArray.count)
			tableView.reloadData()
		}
	}
}
