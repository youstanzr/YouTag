//
//  MenuViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/13/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import XCDYouTubeKit

class MenuViewController: UIViewController, DownloadWebViewDelegate {
	let addButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = UIColor(red: 0.984, green: 0.588, blue: 0.188, alpha: 1.0)
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 50)
		btn.setTitle("+", for: .normal)
		btn.contentVerticalAlignment = .top
		btn.titleEdgeInsets = UIEdgeInsets(top: -10.0, left: 0.0, bottom: 0.0, right: 0.0)
		btn.addBorder(side: .left, color: .darkGray, width: 1.0)
		return btn
	}()
	let dismissButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = UIColor(red: 0.984, green: 0.588, blue: 0.188, alpha: 1.0)
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 30)
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
        self.libraryTableView.LM.refreshLibraryArray()
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
	
	func retrievedVideoLink(videoLink: String) {
		self.initVideoProcess(link: videoLink)
	}

    func initVideoProcess(link:String) {
        if let videoID = self.extractVideoId(link: link) {
			print("link is valid - Video ID: \(videoID)")
			if !self.LM.checkSongExistInLibrary(songID: videoID) {  //check if video not already in library
				self.loadVideo(videoID: videoID)
			} else {
				let alert = UIAlertController(title: "Error", message: "Video already exists in library", preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
				self.present(alert, animated: true, completion: nil)
			}
        } else {
            print("link is not valid")
            let alert = UIAlertController(title: "Error", message: "Link is not valid", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
        
    func loadVideo(videoID:String) {
        print("Loading url: https://www.youtube.com/embed/\(videoID)")
        self.showSpinner(onView: self.view)
        XCDYouTubeClient.default().getVideoWithIdentifier(videoID) { (video, error) in
            guard video != nil else {
				self.removeSpinner()
                print(error?.localizedDescription as Any)
                return
            }
            _ = self.LM.addSongToLibrary(songTitle: video!.title, videoUrl: video!.streamURL, thumbnailUrl: video!.thumbnailURL!, duration: video!.duration.stringFromTimeInterval(), songID: videoID)
			self.libraryTableView.refreshTableView()
			self.removeSpinner()
        }
    }
        
    func extractVideoId(link:String) -> String? {
        let pattern = #"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)"#
        if let matchRange = link.range(of: pattern, options: .regularExpression) {
            return String(link[matchRange])
        } else {
            return .none
        }
    }

    @objc func dismiss(sender: UIButton) {
        print("dismiss tapped")
        dismiss(animated: true, completion: nil)
    }
}
