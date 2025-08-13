//
//  ViewController.swift
//  YouTag
//
//  Created by Youstanzr on 8/12/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

// Cache issue not well and not invalidated after update pic

import UIKit

class ViewController: UIViewController, FilterPickerViewDelegate, YYTTagViewDelegate {
    
    // MARK: - Properties
    var tagsView: YYTFilterTagView!
    let playlistManager = PlaylistManager.shared
    var filterPickerView: FilterPickerView!
    
    // AND/OR UI
    private var isAndMode: Bool = false // false = OR (default), true = AND
    private lazy var filterModeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("OR", for: .normal)
        btn.setTitleColor(GraphicColors.cloudWhite, for: .normal)
        btn.backgroundColor = .clear
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.layer.cornerRadius = 5
        btn.layer.borderColor = GraphicColors.orange.cgColor
        btn.layer.borderWidth = 1.0
        btn.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(toggleFilterLogic), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - UI Elements
    var menuButton: UIButton = {
        let btn = UIButton()
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "list")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        return btn
    }()
    var filterButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "filter"), for: .normal)
        return btn
    }()
    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "BATTA PLAYER"
        lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 28)
        lbl.textAlignment = .left
        lbl.textColor = GraphicColors.cloudWhite
        return lbl
    }()
    let versionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "v" + UIApplication.shared.version!
        lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 14)
        lbl.textAlignment = .right
        lbl.textColor = GraphicColors.darkGray
        return lbl
    }()
    let buildLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "v" + UIApplication.shared.buildNumber!
        lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 14)
        lbl.textAlignment = .right
        lbl.textColor = GraphicColors.darkGray
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
        playlistManager.computePlaylist(mode: isAndMode ? .and : .or)
        playlistManager.playlistLibraryView.scrollToTop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playlistManager.audioPlayer.pause()
    }
    
    // Automatically present LibraryViewController if library is empty
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        view.backgroundColor = GraphicColors.obsidianBlack
        
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
        
        // Style tags view corners: all rounded except top-right
        tagsView.layer.cornerRadius = 5
        tagsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tagsView.clipsToBounds = true

        // AND/OR toggle button
        view.addSubview(filterModeButton)
        
        // Version Label
        view.addSubview(versionLabel)

        // Build Label
        view.addSubview(buildLabel)

        // Playlist Manager Views
        playlistManager.nowPlayingView.backgroundColor = .clear
        playlistManager.nowPlayingView.addBorder(side: .top, color: GraphicColors.darkGray, width: 0.5)
        playlistManager.nowPlayingView.addBorder(side: .bottom, color: GraphicColors.darkGray, width: 0.5)
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
        logoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        logoView.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -20).isActive = true
        logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        logoView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1).isActive = true

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.leadingAnchor.constraint(equalTo: logoView.leadingAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: logoView.centerYAnchor).isActive = true
        logoImageView.heightAnchor.constraint(equalTo: logoView.heightAnchor).isActive = true
        // Maintain aspect ratio for the image
        logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: 1.0).isActive = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: logoView.trailingAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor, constant: 3).isActive = true
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

        // AND/OR Toggle Button
        filterModeButton.translatesAutoresizingMaskIntoConstraints = false
        filterModeButton.trailingAnchor.constraint(equalTo: tagsView.trailingAnchor).isActive = true
        filterModeButton.bottomAnchor.constraint(equalTo: tagsView.topAnchor, constant: 1).isActive = true
        filterModeButton.heightAnchor.constraint(equalToConstant: 22).isActive = true
        filterModeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        // Build Label
        buildLabel.translatesAutoresizingMaskIntoConstraints = false
        buildLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35).isActive = true
        buildLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true
        buildLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1).isActive = true
        buildLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true

        // Version Label
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -35).isActive = true
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
        })
    }
    
    @objc func filterButtonAction(sender: UIButton!) {
        print("Filter Button tapped")
        filterPickerView.show(animated: true)
    }
    
    @objc private func toggleFilterLogic() {
        print("Toggle filter logic")
        isAndMode.toggle()
        filterModeButton.setTitle(isAndMode ? "AND" : "OR", for: .normal)
        playlistManager.computePlaylist(mode: isAndMode ? .and : .or)
    }
    
    // MARK: YYTTagViewDelegate
    // When filter tags are changed by delete
    func tagsListChanged(newTagsList: [[String]]) {
        print("New tags list: \(newTagsList)")
        let existingFilters = playlistManager.playlistFilters.getFilters()
        
        let removedFilters = existingFilters.filter { !newTagsList.contains($0) }
        for filter in removedFilters {
            playlistManager.playlistFilters.deleteFilter(type: PlaylistFilters.FilterType(rawValue: filter[0])!, value: filter[1])
        }

        playlistManager.computePlaylist(mode: isAndMode ? .and : .or)
    }

    // MARK: FilterPickerViewDelegate
    // When filter tags are changed by addition
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
        playlistManager.computePlaylist(mode: isAndMode ? .and : .or)

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
