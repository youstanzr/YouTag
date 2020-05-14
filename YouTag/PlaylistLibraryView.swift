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
	
    var playlistArray: [Song] = []

	
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
        let song = playlistArray[indexPath.row]
        
		cell.song = song
		cell.refreshCell()
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as! LibraryCell

        print("Selected cell number \(indexPath.row) -> \(cell.song?.title ?? "")")
        guard let last = playlistArray.last else { return }
//        playlistArray.insert(last, at: 0)
//        playlistArray.removeLast()
//        playlistArray.remove(at: indexPath.row)
//        playlistArray.append(<#T##newElement: Song##Song#>)
        print(#function)
        

//		playlistArray.insert(playlistArray.lastObject!, at: 0)
//		playlistArray.removeLastObject()
//		playlistArray.remove(cell.songDict)
//		playlistArray.add(cell.songDict)
//
//		tableView.deselectRow(at: indexPath, animated: false)
//		tableView.reloadData()
//
//		PLDelegate?.didSelectSong(songDict: cell.songDict)
    }
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        playlistArray.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
	}
	
}
