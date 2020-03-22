//
//  LibraryTableView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/27/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class LibraryTableView: UITableView, UITableViewDelegate, UITableViewDataSource{
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
        
		let songDict = LM.libraryArray.object(at: indexPath.row) as! Dictionary<String, Any>
		cell.songDict = songDict
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
        print("Selected cell number: \(indexPath.row)")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
		let cell = tableView.cellForRow(at: indexPath) as! LibraryCell
		let songDetail_vc: SongDetailViewController = storyboard.instantiateViewController(withIdentifier: "SongDetailViewController") as! SongDetailViewController
        songDetail_vc.modalPresentationStyle = .fullScreen
        songDetail_vc.modalTransitionStyle = .coverVertical

		songDetail_vc.songDict = cell.songDict

        let currentController = self.getCurrentViewController()
        currentController?.present(songDetail_vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let cell = tableView.cellForRow(at: indexPath) as! LibraryCell
			LM.deleteSongFromLibrary(songID: cell.songDict["id"] as? String ?? "")
            LM.refreshLibraryArray()
            tableView.reloadData()
        }
    }
}
