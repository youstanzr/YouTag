//
//  ViewController.swift
//  YouTag
//
//  Created by Youstanzr on 8/12/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FilterPickerViewDelegate, YYTTagViewDelegate {
    
    // MARK: - Properties
    var tagsView: YYTFilterTagView!
    let playlistManager = PlaylistManager.shared
    var filterPickerView: FilterPickerView!
    
    // MARK: - UI Elements
    var menuButton: UIButton = {
        let btn = UIButton()
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "list"), for: .normal)
        return btn
    }()
    var filterButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "filter"), for: .normal)
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
        lbl.text = "v" + UIApplication.shared.buildNumber!
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
    let logoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playlistManager.computePlaylist()
        playlistManager.playlistLibraryView.scrollToTop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playlistManager.audioPlayer.pause()
    }
    
    // Automatically present LibraryViewController if library is empty
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Refresh library data
        LibraryManager.shared.refreshLibraryArray()
        // If no songs in the library, prompt user to add
        if LibraryManager.shared.libraryArray.isEmpty {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let libraryVC = storyboard.instantiateViewController(withIdentifier: "LibraryViewController") as? LibraryViewController {
                libraryVC.modalPresentationStyle = .fullScreen
                present(libraryVC, animated: false, completion: nil)
            }
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = GraphicColors.backgroundWhite
        
        // Logo View
        view.addSubview(logoView)
        logoView.addSubview(logoImageView)
        logoView.addSubview(titleLabel)
        
        // Menu and Filter Buttons
        menuButton.addTarget(self, action: #selector(menuButtonAction), for: .touchUpInside)
        view.addSubview(menuButton)
        
        filterButton.addTarget(self, action: #selector(filterButtonAction), for: .touchUpInside)
        view.addSubview(filterButton)
        
        // Tags View
        tagsView = YYTFilterTagView(frame: .zero, tupleTags: [], isDeleteEnabled: true)
        tagsView.yytdelegate = self
        view.addSubview(tagsView)
        
        // Version Label
        view.addSubview(versionLabel)
        
        // Playlist Manager Views
        playlistManager.nowPlayingView.backgroundColor = .clear
        playlistManager.nowPlayingView.addBorder(side: .top, color: .lightGray, width: 1.0)
        playlistManager.nowPlayingView.addBorder(side: .bottom, color: .lightGray, width: 1.0)
        view.addSubview(playlistManager.nowPlayingView)
        
        playlistManager.playlistLibraryView.backgroundColor = .clear
        view.addSubview(playlistManager.playlistLibraryView)
        
        // Filter Picker View
        filterPickerView = FilterPickerView()
        filterPickerView.delegate = self
        view.addSubview(filterPickerView)
    }

    // MARK: - Constraints
    private func setupConstraints() {
        // Logo View
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        logoView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.29).isActive = true
        logoView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.09).isActive = true

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.leadingAnchor.constraint(equalTo: logoView.leadingAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: logoView.centerYAnchor).isActive = true
        logoImageView.widthAnchor.constraint(equalTo: logoView.widthAnchor, multiplier: 0.4).isActive = true
        logoImageView.heightAnchor.constraint(equalTo: logoView.heightAnchor).isActive = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.trailingAnchor.constraint(equalTo: logoView.trailingAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor, constant: 3).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: logoView.widthAnchor, multiplier: 0.58).isActive = true
        titleLabel.heightAnchor.constraint(equalTo: logoView.heightAnchor).isActive = true

        // Menu Button
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        menuButton.topAnchor.constraint(equalTo: self.logoView.topAnchor).isActive = true
        menuButton.widthAnchor.constraint(equalTo: self.logoView.heightAnchor, multiplier: 0.8).isActive = true
        menuButton.heightAnchor.constraint(equalTo: self.logoView.heightAnchor).isActive = true

        // Filter Button
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.trailingAnchor.constraint(equalTo: menuButton.trailingAnchor).isActive = true
        filterButton.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 15).isActive = true
        filterButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        filterButton.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true

        // Tags View
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        tagsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        tagsView.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -10).isActive = true
        tagsView.topAnchor.constraint(equalTo: filterButton.topAnchor).isActive = true
        tagsView.heightAnchor.constraint(equalTo: filterButton.heightAnchor).isActive = true

        // Version Label
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35).isActive = true
        versionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true
        versionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1).isActive = true
        versionLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true

        // Now Playing View
        playlistManager.nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        playlistManager.nowPlayingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playlistManager.nowPlayingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playlistManager.nowPlayingView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 15).isActive = true
        playlistManager.nowPlayingView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true

        // Playlist Library View
        playlistManager.playlistLibraryView.translatesAutoresizingMaskIntoConstraints = false
        playlistManager.playlistLibraryView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playlistManager.playlistLibraryView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playlistManager.playlistLibraryView.topAnchor.constraint(equalTo: playlistManager.nowPlayingView.bottomAnchor, constant: 5).isActive = true
        playlistManager.playlistLibraryView.bottomAnchor.constraint(equalTo: versionLabel.topAnchor).isActive = true

        // Filter Picker View
        filterPickerView.translatesAutoresizingMaskIntoConstraints = false
        filterPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        filterPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        filterPickerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        filterPickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    // MARK: - Button Actions
    @objc func menuButtonAction(sender: UIButton!) {
        print("Menu Button tapped")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let LVC: LibraryViewController = storyboard.instantiateViewController(withIdentifier: "LibraryViewController") as! LibraryViewController
        LVC.modalPresentationStyle = .fullScreen
        LVC.modalTransitionStyle = .coverVertical
        self.present(LVC, animated: true, completion: {
            self.tagsView.removeAllTags()
            self.playlistManager.audioPlayer.pause()
        })
    }
    
    @objc func filterButtonAction(sender: UIButton!) {
        print("Filter Button tapped")
        filterPickerView.show(animated: true)
    }
    
    // MARK: YYTTagViewDelegate
    //For tag list that shows the chosen tags
    func tagsListChanged(newTagsList: [[String]]) {
        print("New tags list: \(newTagsList)")
        let existingFilters = playlistManager.playlistFilters.getFilters()
        
        let removedFilters = existingFilters.filter { !newTagsList.contains($0) }
        for filter in removedFilters {
            playlistManager.playlistFilters.deleteFilter(type: PlaylistFilters.FilterType(rawValue: filter[0])!, value: filter[1])
        }

        playlistManager.computePlaylist()
    }

    // MARK: FilterPickerViewDelegate
    //For the tag list the are added
    func processNewFilter(type: PlaylistFilters.FilterType, filters: [Any]) {
        switch type {
            case .tag, .artist, .album:
                let stringFilters = filters.compactMap { $0 as? String }
                playlistManager.playlistFilters.addUniqueFilter(type: type, values: stringFilters)
            case .releaseYear:
                let intFilters = filters.compactMap { Int($0 as! String) }
                playlistManager.playlistFilters.addUniqueFilter(type: type, values: intFilters)
            case .releaseYearRange:
                playlistManager.playlistFilters.addUniqueFilter(type: type, values: filters)
            case .duration:
                // Expect a flat [TimeInterval] array [lower, upper]
                let values = filters.compactMap { $0 as? TimeInterval }
                let durationFilters: [[TimeInterval]] = [values]
                playlistManager.playlistFilters.addUniqueFilter(type: type, values: durationFilters)
        }
        playlistManager.computePlaylist()
        // Update tags view using helper conversion
        let rawFilters = playlistManager.playlistFilters.getFilters()
        let tupleFilters = convertFiltersToTuples(rawFilters)
        tagsView.updateTags(with: tupleFilters)
    }
    
    // MARK: Helpers
    /// Converts an array of [String] pairs into [(FilterType, String)] tuples.
    private func convertFiltersToTuples(_ rawFilters: [[String]]) -> [(PlaylistFilters.FilterType, String)] {
        return rawFilters.compactMap { pair in
            guard pair.count == 2,
                  let filterType = PlaylistFilters.FilterType(rawValue: pair[0]) else {
                return nil
            }
            return (filterType, pair[1])
        }
    }

}
