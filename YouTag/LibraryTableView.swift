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
        self.layer.cornerRadius = 2.5
        self.backgroundColor = UIColor.clear
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
        cell.backgroundColor = UIColor.clear
        
		let songDict = LM.libraryArray.object(at: indexPath.row) as! Dictionary<String, Any>
		cell.songID = songDict["songID"] as! String
		cell.titleLabel.text = songDict["songTitle"] as? String
		cell.artistLabel.text = songDict["artistName"] as? String
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(cell.songID).jpg"))
		cell.thumbnailImageView.image = UIImage(data: imageData ?? Data())
		cell.durationLabel.text = songDict["duration"] as? String
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
		#warning("Can change the cell to have the song dict so we remove the getSong by id func call")
        songDetail_vc.songDict = LM.getSong(forID: cell.songID)

        let currentController = self.getCurrentViewController()
        currentController?.present(songDetail_vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let cell = tableView.cellForRow(at: indexPath) as! LibraryCell
            LM.deleteSongFromLibrary(songID: cell.songID)
            LM.refreshLibraryArray()
            tableView.reloadData()
        }
    }
}
