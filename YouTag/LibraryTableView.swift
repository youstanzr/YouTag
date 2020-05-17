//
//  LibraryTableView.swift
//  YouTag
//
//  Created by Youstanzr on 2/27/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class LibraryTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
 
    // Thats actually kind of dangerous because your library manager's songs array can change somewhere else
    // this will lead to tableview problems since count changed
	var LM: LibraryManager!

	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
        LM = LibraryManager.init()

		self.register(LibraryCell.self, forCellReuseIdentifier: "LibraryCell")
        self.delegate = self
        self.dataSource = self
    }

    func refreshTableView() {
        self.LM.refreshLibraryArray()
        self.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LM.libraryArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath as IndexPath) as! LibraryCell
        
        let song = LM.libraryArray[indexPath.row]
		cell.song = song
		cell.refreshCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = LM.libraryArray[indexPath.row]
        
        print("Selected cell number: \(indexPath.row)")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
		let songDetail_vc: SongDetailViewController = storyboard.instantiateViewController(withIdentifier: "SongDetailViewController") as! SongDetailViewController
        
        songDetail_vc.modalPresentationStyle = .fullScreen
        songDetail_vc.modalTransitionStyle = .coverVertical
        
		songDetail_vc.song = song
        songDetail_vc.delegate = self

        let currentController = UIApplication.getCurrentViewController()
        currentController?.present(songDetail_vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let song = LM.libraryArray[indexPath.row]
        LM.deleteSongFromLibrary(songID: song.id)
        LM.refreshLibraryArray()
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
	
}

// MARK: SongDetailDelegate {

extension LibraryTableView: SongDetailDelegate {
    
    func onSongUpdated() {
        reloadData()
    }
}
