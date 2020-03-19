//
//  ViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/12/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TagPickerViewDelegate, YTTagViewDelegate{
	var tagsView: YTTagView!
	var nowPlayingView: NowPlayingView!
    var nowPlayingLibraryView: NowPlayingLibraryView!
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
		lbl.text = "v20200318"
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
        // Do any additional setup after loading the view.
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
		
		nowPlayingView = NowPlayingView(frame: .zero)
		nowPlayingView.addBorder(side: .top, color: .lightGray, width: 1.0)
		nowPlayingView.addBorder(side: .bottom, color: .lightGray, width: 1.0)
        self.view.addSubview(nowPlayingView)
		nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
		nowPlayingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		nowPlayingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		nowPlayingView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 15).isActive = true
		nowPlayingView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.225).isActive = true
		
		nowPlayingLibraryView = NowPlayingLibraryView(frame: .zero)
        self.view.addSubview(nowPlayingLibraryView)
		nowPlayingLibraryView.translatesAutoresizingMaskIntoConstraints = false
		nowPlayingLibraryView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 5).isActive = true
		nowPlayingLibraryView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5).isActive = true
		nowPlayingLibraryView.topAnchor.constraint(equalTo: nowPlayingView.bottomAnchor, constant: 10).isActive = true
		nowPlayingLibraryView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true

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
		self.nowPlayingLibraryView.updateTagsList(to: self.tagsView.tagsList)
		if self.nowPlayingLibraryView.playlistArray.count > 0 {
			let sd = self.nowPlayingLibraryView.playlistArray.object(at: 0) as! Dictionary<String, Any>
			nowPlayingView.updateSongDict(to: sd)
		} else {
			nowPlayingView.updateSongDict(to: Dictionary<String, Any>())
		}
    }
	
    @objc func menuButtonAction(sender: UIButton!) {
        print("Menu Button tapped")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let menu_vc: MenuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        menu_vc.modalPresentationStyle = .fullScreen
        menu_vc.modalTransitionStyle = .coverVertical
        self.present(menu_vc, animated: true, completion: nil)
    }

    @objc func filterButtonAction(sender: UIButton!) {
        print("Filter Button tapped")
		tagPickerView.show(withAnimation: true)
    }
	
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
		self.nowPlayingLibraryView.updateTagsList(to: self.tagsView.tagsList)
	}
	
	func tagsListChanged(newTagsList: NSMutableArray) {
		self.nowPlayingLibraryView.updateTagsList(to: self.tagsView.tagsList)
	}
}