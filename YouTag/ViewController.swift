//
//  ViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/12/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TagPickerViewDelegate, YTTagViewDelegate {
	var tagsView: YTTagView!
	var playlistManager = PlaylistManager()
	var tagPickerView: TagPickerView!
	var menuButton: UIButton = {
		let btn = UIButton()
		btn.imageView!.contentMode = .scaleAspectFit
		btn.setImage(UIImage(named: "List_Image"), for: UIControl.State.normal)
		return btn
	}()
	var filterButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "Filter_Image"), for: UIControl.State.normal)
		return btn
	}()
	let titleLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "YouTag"
		lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 28)
		lbl.textAlignment = .left
		return lbl
	}()
	let versionLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "v20200319"
		lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 14)
		lbl.textAlignment = .right
		lbl.textColor = .lightGray
		return lbl
	}()
	let logoImageView: UIImageView = {
		let imgView = UIImageView(image: UIImage(named: "Logo_Image"))
		imgView.contentMode = .scaleAspectFit
		return imgView
	}()

	override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)
		
		self.view.addSubview(logoImageView)
		logoImageView.translatesAutoresizingMaskIntoConstraints = false
		logoImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
		logoImageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 44).isActive = true
		logoImageView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.1).isActive = true
		logoImageView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.07).isActive = true

		self.view.addSubview(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.leadingAnchor.constraint(equalTo: self.logoImageView.trailingAnchor, constant: 2.5).isActive = true
		titleLabel.topAnchor.constraint(equalTo: logoImageView.topAnchor).isActive = true
		titleLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
		titleLabel.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.09).isActive = true
		
		menuButton.addTarget(self, action: #selector(menuButtonAction), for: .touchUpInside)
		self.view.addSubview(menuButton)
		menuButton.translatesAutoresizingMaskIntoConstraints = false
		menuButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
		menuButton.topAnchor.constraint(equalTo: self.logoImageView.topAnchor).isActive = true
		menuButton.widthAnchor.constraint(equalTo: self.logoImageView.widthAnchor).isActive = true
		menuButton.heightAnchor.constraint(equalTo: self.logoImageView.heightAnchor).isActive = true

        filterButton.addTarget(self, action: #selector(filterButtonAction), for: .touchUpInside)
        self.view.addSubview(filterButton)
		filterButton.translatesAutoresizingMaskIntoConstraints = false
		filterButton.trailingAnchor.constraint(equalTo: self.menuButton.trailingAnchor).isActive = true
		filterButton.topAnchor.constraint(equalTo: self.menuButton.bottomAnchor, constant: 15).isActive = true
		filterButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.2).isActive = true
		filterButton.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.2).isActive = true

		tagsView = YTTagView(frame: .zero, tagsList: NSMutableArray(), isAddable: false, isMultiSelection: false)
		tagsView.ytdelegate = self
		self.view.addSubview(tagsView)
		tagsView.translatesAutoresizingMaskIntoConstraints = false
		tagsView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
		tagsView.trailingAnchor.constraint(equalTo: self.filterButton.leadingAnchor, constant: -10).isActive = true
		tagsView.topAnchor.constraint(equalTo: filterButton.topAnchor).isActive = true
		tagsView.heightAnchor.constraint(equalTo: filterButton.heightAnchor).isActive = true
		
		playlistManager.nowPlayingView.backgroundColor = .clear
		playlistManager.nowPlayingView.addBorder(side: .top, color: .lightGray, width: 1.0)
		playlistManager.nowPlayingView.addBorder(side: .bottom, color: .lightGray, width: 1.0)
        self.view.addSubview(playlistManager.nowPlayingView)
		playlistManager.nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
		playlistManager.nowPlayingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		playlistManager.nowPlayingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		playlistManager.nowPlayingView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 15).isActive = true
		playlistManager.nowPlayingView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
		
		playlistManager.playlistLibraryView.backgroundColor = .clear
        self.view.addSubview(playlistManager.playlistLibraryView)
		playlistManager.playlistLibraryView.translatesAutoresizingMaskIntoConstraints = false
		playlistManager.playlistLibraryView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 5).isActive = true
		playlistManager.playlistLibraryView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5).isActive = true
		playlistManager.playlistLibraryView.topAnchor.constraint(equalTo: playlistManager.nowPlayingView.bottomAnchor, constant: 10).isActive = true
		playlistManager.playlistLibraryView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true

		self.view.addSubview(versionLabel)
		versionLabel.translatesAutoresizingMaskIntoConstraints = false
		versionLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
		versionLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25).isActive = true
		versionLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -1).isActive = true
		versionLabel.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.075).isActive = true

		tagPickerView = TagPickerView()
		tagPickerView.delegate = self
		self.view.addSubview(tagPickerView)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		playlistManager.updateTagsList(to: self.tagsView.tagsList)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		playlistManager.audioPlayer.pause()
	}
    	
    @objc func menuButtonAction(sender: UIButton!) {
        print("Menu Button tapped")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let LVC: LibraryViewController = storyboard.instantiateViewController(withIdentifier: "LibraryViewController") as! LibraryViewController
        LVC.modalPresentationStyle = .fullScreen
        LVC.modalTransitionStyle = .coverVertical
        self.present(LVC, animated: true, completion: nil)
    }

    @objc func filterButtonAction(sender: UIButton!) {
        print("Filter Button tapped")
		tagPickerView.show(withAnimation: true)
    }
	
	//For the tag list the are added
	func processAddedTags(addedTagsList: NSMutableArray) {
		//Remove the tags already present in the tagsView
		var i = 0
		while i < addedTagsList.count {
			if self.tagsView.tagsList.contains(addedTagsList.object(at: i)) {
				addedTagsList.removeObject(at: i)
				i -= 1
			}
			i += 1
		}
		//Add the newly added tags
		self.tagsView.addTags(tagList: addedTagsList)
		playlistManager.updateTagsList(to: self.tagsView.tagsList)
	}
	
	//For tag list that shows the chosen tags
	func tagsListChanged(newTagsList: NSMutableArray) {
		playlistManager.updateTagsList(to: self.tagsView.tagsList)
	}
}
