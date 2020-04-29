//
//  ViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/12/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FilterPickerViewDelegate, YYTTagViewDelegate {
	
	var tagsView: YYTFilterTagView!
	var playlistManager = PlaylistManager()
	var filterPickerView: FilterPickerView!
	var menuButton: UIButton = {
		let btn = UIButton()
		btn.imageView!.contentMode = .scaleAspectFit
		btn.setImage(UIImage(named: "list"), for: UIControl.State.normal)
		return btn
	}()
	var filterButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "filter"), for: UIControl.State.normal)
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
		lbl.text = "v20200429"
		lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 14)
		lbl.textAlignment = .right
		lbl.textColor = .lightGray
		return lbl
	}()
	let logoImageView: UIImageView = {
		let imgView = UIImageView(image: UIImage(named: "logo"))
		imgView.contentMode = .scaleAspectFit
		return imgView
	}()

	
	override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = GraphicColors.backgroundWhite
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

		tagsView = YYTFilterTagView(frame: .zero, tagsList: NSMutableArray(), isAddEnabled: false, isMultiSelection: false, isDeleteEnabled: true)
		tagsView.yytdelegate = self
		self.view.addSubview(tagsView)
		tagsView.translatesAutoresizingMaskIntoConstraints = false
		tagsView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
		tagsView.trailingAnchor.constraint(equalTo: self.filterButton.leadingAnchor, constant: -10).isActive = true
		tagsView.topAnchor.constraint(equalTo: filterButton.topAnchor).isActive = true
		tagsView.heightAnchor.constraint(equalTo: filterButton.heightAnchor).isActive = true
		
		self.view.addSubview(versionLabel)
		versionLabel.translatesAutoresizingMaskIntoConstraints = false
		versionLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
		versionLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25).isActive = true
		versionLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -1).isActive = true
		versionLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true

		playlistManager.nowPlayingView.backgroundColor = .clear
		playlistManager.nowPlayingView.addBorder(side: .top, color: .lightGray, width: 1.0)
		playlistManager.nowPlayingView.addBorder(side: .bottom, color: .lightGray, width: 1.0)
        self.view.addSubview(playlistManager.nowPlayingView)
		playlistManager.nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
		playlistManager.nowPlayingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		playlistManager.nowPlayingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		playlistManager.nowPlayingView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 15).isActive = true
		playlistManager.nowPlayingView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.2).isActive = true
		
		playlistManager.playlistLibraryView.backgroundColor = .clear
        self.view.addSubview(playlistManager.playlistLibraryView)
		playlistManager.playlistLibraryView.translatesAutoresizingMaskIntoConstraints = false
		playlistManager.playlistLibraryView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 5).isActive = true
		playlistManager.playlistLibraryView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5).isActive = true
		playlistManager.playlistLibraryView.topAnchor.constraint(equalTo: playlistManager.nowPlayingView.bottomAnchor, constant: 5).isActive = true
		playlistManager.playlistLibraryView.bottomAnchor.constraint(equalTo: versionLabel.topAnchor).isActive = true

		filterPickerView = FilterPickerView()
		filterPickerView.delegate = self
		self.view.addSubview(filterPickerView)
		filterPickerView.translatesAutoresizingMaskIntoConstraints = false
		filterPickerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		filterPickerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		filterPickerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
		filterPickerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
	}
		
	override func viewWillAppear(_ animated: Bool) {
		playlistManager.computePlaylist()
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
		filterPickerView.show(animated: true)
    }

	// MARK: YYTTagViewDelegate
	//For tag list that shows the chosen tags
	func tagsListChanged(newTagsList: NSMutableArray) {
		let filtersArr = playlistManager.playlistFilters.getFilters()
		let deletedFilters = NSMutableArray()
		for i in 0 ..< filtersArr.count {
			if !newTagsList.contains(filtersArr.object(at: i)) {
				deletedFilters.add(filtersArr.object(at: i))
			}
		}
		playlistManager.playlistFilters.deleteFilter(using: deletedFilters)
		playlistManager.computePlaylist()
	}
	
	// MARK: FilterPickerViewDelegate
	//For the tag list the are added
	func processNewFilter(type: String, filters: NSMutableArray) {
		playlistManager.playlistFilters.addUniqueFilter(filters, type: PlaylistFilters.FilterType(rawValue: type)!)
		playlistManager.computePlaylist()
		tagsView.tagsList = playlistManager.playlistFilters.getFilters()
		tagsView.reloadData()
	}

}
