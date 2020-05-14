//
//  LibraryViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/13/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import XCDYouTubeKit

class LibraryViewController: UIViewController, DownloadWebViewDelegate {

	let addButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = GraphicColors.orange
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 48)
		btn.setTitle("+", for: .normal)
		btn.contentVerticalAlignment = .top
		btn.titleEdgeInsets = UIEdgeInsets(top: -10.0, left: 0.0, bottom: 0.0, right: 0.0)
		btn.addBorder(side: .left, color: .darkGray, width: 1.0)
		return btn
	}()
	let dismissButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = GraphicColors.orange
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 32)
		btn.setTitle("✔︎", for: .normal)
		btn.contentVerticalAlignment = .top
		btn.titleEdgeInsets = UIEdgeInsets(top: 2.5, left: 0.0, bottom: 0.0, right: 0.0)
		btn.addBorder(side: .right, color: .darkGray, width: 1.0)
		return btn
	}()
	let libraryTableView = LibraryTableView()
	let LM = LibraryManager()

	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = GraphicColors.backgroundWhite
		
		libraryTableView.backgroundColor = .clear
		self.view.addSubview(libraryTableView)
		libraryTableView.translatesAutoresizingMaskIntoConstraints = false
		libraryTableView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		libraryTableView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -5).isActive = true
		libraryTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 35).isActive = true
		libraryTableView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.85).isActive = true
		
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        self.view.addSubview(addButton)
		addButton.translatesAutoresizingMaskIntoConstraints = false
		addButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		addButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
		addButton.topAnchor.constraint(equalTo: libraryTableView.bottomAnchor, constant: 5).isActive = true
		addButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        self.view.addSubview(dismissButton)
		dismissButton.translatesAutoresizingMaskIntoConstraints = false
		dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		dismissButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
		dismissButton.topAnchor.constraint(equalTo: libraryTableView.bottomAnchor, constant: 5).isActive = true
		dismissButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.LM.refreshLibraryArray()
        self.libraryTableView.refreshTableView()
    }

    @objc func addButtonAction(sender: UIButton!) {
        print("Add Button tapped")
		let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
		let dwvc: DownloadWebViewController = storyboard.instantiateViewController(withIdentifier: "DownloadWebViewController") as! DownloadWebViewController
		dwvc.delegate = self
		dwvc.modalPresentationStyle = .fullScreen
		dwvc.modalTransitionStyle = .coverVertical
		self.present(dwvc, animated: true, completion: nil)
    }
	
	func requestedDownloadLink(link: String, contentType fileExtension: String) {
		if ["m.youtube.com", "youtube.com"].contains(URL(string: link)?.host) {
			self.processYoutubeVideo(link: link)
		} else {
			self.processDirectLink(link: link, contentType: fileExtension)
		}
	}
	
	func processDirectLink(link: String, contentType MIME: String) {
		self.LM.addSongToLibrary(songTitle: nil, songUrl: URL(string: link)!, songExtension: MIME, thumbnailUrl: nil, songID: nil, completion: {
			self.libraryTableView.refreshTableView()
			self.libraryTableView.tableView(self.libraryTableView, didSelectRowAt: IndexPath(row: 0, section: 0))
		})
	}
	
    func processYoutubeVideo(link: String) {
        if let videoID = link.extractYoutubeId() {
			print("Link is valid - Video ID: \(videoID)")
			self.loadYouTubeVideo(videoID: videoID)
        } else {
            print("Link is not valid")
            let alert = UIAlertController(title: "Error", message: "Link is not valid", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
        
    func loadYouTubeVideo(videoID: String) {
        print("Loading url: https://www.youtube.com/embed/\(videoID)")
		self.showSpinner(onView: self.view, withTitle: "Loading...")
        XCDYouTubeClient.default().getVideoWithIdentifier(videoID) { (video, error) in
            guard video != nil else {
				print(error?.localizedDescription as Any)
				self.removeSpinner()
				let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
				self.present(alert, animated: true, completion: nil)
                return
            }
			self.removeSpinner()
			self.LM.addSongToLibrary(songTitle: video!.title, songUrl: video!.streamURL, songExtension: "mp4", thumbnailUrl: video!.thumbnailURLs![video!.thumbnailURLs!.count/2], songID: videoID, completion: {
				self.libraryTableView.refreshTableView()
				self.libraryTableView.tableView(self.libraryTableView, didSelectRowAt: IndexPath(row: 0, section: 0))
			})
        }
    }

    @objc func dismiss(sender: UIButton) {
        print("dismiss tapped")
        dismiss(animated: true, completion: nil)
    }
	
}
