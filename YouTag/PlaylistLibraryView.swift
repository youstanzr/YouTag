//
//  PlaylistLibraryView.swift
//  YouTag
//
//  Created by Youstanzr on 2/29/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

protocol PlaylistLibraryViewDelegate: class {
	func didSelectSong(songDict: Dictionary<String, Any>)
}

class PlaylistLibraryView: LibraryTableView {

	weak var PLDelegate: PlaylistLibraryViewDelegate?
	
	var playlistArray = NSMutableArray()

	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		playlistArray = LM.libraryArray
    }
	
	override func refreshTableView() {
		self.reloadData()
	}
		
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return playlistArray.count-1
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath as IndexPath) as! LibraryCell

		let songDict = playlistArray.object(at: (playlistArray.count - 2 - indexPath.row) % playlistArray.count) as! Dictionary<String, Any>
		cell.songDict = songDict
		cell.refreshCell()
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as! LibraryCell

		print("Selected cell number \(indexPath.row) -> \(cell.songDict["title"] ?? "")")

		playlistArray.insert(playlistArray.lastObject!, at: 0)
		playlistArray.removeLastObject()
		playlistArray.remove(cell.songDict)
		playlistArray.add(cell.songDict)
		
		tableView.deselectRow(at: indexPath, animated: false)
		tableView.reloadData()
		
		PLDelegate?.didSelectSong(songDict: cell.songDict)
    }
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			playlistArray.removeObject(at: (playlistArray.count - 2 - indexPath.row) % playlistArray.count)
			tableView.reloadData()
		}
	}
	
}
