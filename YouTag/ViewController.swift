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
    
    // Height constraint for playlist control view
    private var playlistControlHeightConstraint: NSLayoutConstraint!
    private var playlistControlBaseHeight: CGFloat = 60
    // Tracks whether lyrics panel is shown (affects control height)
    private var isLyricsShown: Bool = false

    // Constraint groups
    private var commonConstraints: [NSLayoutConstraint] = []
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []
    
    // AND/OR UI
    private var isAndMode: Bool = false // false = OR (default), true = AND
    private lazy var filterModeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("OR", for: .normal)
        btn.setTitleColor(GraphicColors.cloudWhite, for: .normal)
        btn.backgroundColor = GraphicColors.orange
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.layer.cornerRadius = 5
        btn.layer.borderColor = GraphicColors.orange.cgColor
        btn.layer.borderWidth = 1.0
        btn.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(toggleFilterMode), for: .touchUpInside)
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
        lbl.textAlignment = .left
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
//        Task { await LibraryManager.shared.recomputeSongDurations() }
        setupUI()
        setupConstraints()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLyricsToggle(_:)),
                                               name: .playlistControlLyricsToggled,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onPlaylistWillUpdate),
                                               name: .playlistWillUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onPlaylistDidUpdate),
                                               name: .playlistDidUpdate,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playlistManager.computePlaylistIfNeeded(mode: isAndMode ? .and : .or)
        playlistManager.playlistTableView.scrollToTop()
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
    
    // MARK: Playlist Manager
    @objc private func onPlaylistWillUpdate(_ note: Notification) {
        // Collapse BEFORE any table reloads happen, no animation to avoid races
        let uiOnly = note.userInfo?["uiOnly"] as! Bool
        if !uiOnly {
            collapsePlaylistControlHeight(animated: true)
        }
    }

    @objc private func onPlaylistDidUpdate(_ note: Notification) {
        // Restore to the correct state based on your flags/orientation
        print("Playlist did update")
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
        
        playlistManager.playlistControlView.addBorder(side: .bottom, color: GraphicColors.darkGray, width: 0.5)
        
        playlistManager.playlistTableView.backgroundColor = .clear
        
        view.addSubview(playlistManager.nowPlayingView)
        view.addSubview(playlistManager.playlistControlView)
        view.addSubview(playlistManager.playlistTableView)
        
        // Filter Picker View
        filterPickerView = FilterPickerView()
        filterPickerView.delegate = self
        view.addSubview(filterPickerView)
    }
    
    // MARK: - Constraint switching
    private func applyConstraints(for traits: UITraitCollection) {
        let isLandscape = traits.verticalSizeClass == .compact
        // Lyrics expand only in portrait
        let shouldExpandLyrics = isLyricsShown && !isLandscape
        let desiredControlHeight = shouldExpandLyrics ? (playlistControlBaseHeight * 2) : playlistControlBaseHeight
        playlistControlHeightConstraint.constant = desiredControlHeight
        if isLandscape {
            playlistControlHeightConstraint.priority = UILayoutPriority(750)
        } else {
            playlistControlHeightConstraint.priority = UILayoutPriority(1000)
        }
        NSLayoutConstraint.deactivate(isLandscape ? portraitConstraints : landscapeConstraints)
        NSLayoutConstraint.activate(isLandscape ? landscapeConstraints : portraitConstraints)
        layoutIfInWindow()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyConstraints(for: traitCollection)
    }

    // Helper: only animate layout if view is in window
    private func layoutIfInWindow(animated: Bool = true) {
        guard self.view.window != nil else { return }
        if animated {
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        } else {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        // Prepare for Auto Layout
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        filterModeButton.translatesAutoresizingMaskIntoConstraints = false
        buildLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        playlistManager.nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        playlistManager.playlistControlView.translatesAutoresizingMaskIntoConstraints = false
        playlistManager.playlistTableView.translatesAutoresizingMaskIntoConstraints = false
        filterPickerView.translatesAutoresizingMaskIntoConstraints = false

        // Now Playing desired height: 12.5% of container, but never below 115pt
        let nowPlayingHeightEq = playlistManager.nowPlayingView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.125)
        nowPlayingHeightEq.priority = UILayoutPriority(999)
        let nowPlayingHeightMin = playlistManager.nowPlayingView.heightAnchor.constraint(greaterThanOrEqualToConstant: 115)

        // COMMON (unchanged between orientations)
        commonConstraints = [
            // Logo container positioning
            logoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            logoView.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -20),
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            // Logo image keeps square aspect & leading
            logoImageView.leadingAnchor.constraint(equalTo: logoView.leadingAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            logoImageView.heightAnchor.constraint(equalTo: logoView.heightAnchor),
            logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: 1.0),

            // Title label fills remaining space
            titleLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: logoView.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor, constant: 3),
            titleLabel.heightAnchor.constraint(equalTo: logoView.heightAnchor),

            // Menu button aligned to top-right, size related to logoView height
            menuButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            menuButton.topAnchor.constraint(equalTo: self.logoView.topAnchor),
            menuButton.widthAnchor.constraint(equalTo: self.logoView.heightAnchor, multiplier: 0.8),
            menuButton.heightAnchor.constraint(equalTo: self.logoView.heightAnchor),

            // Filter button position (below menu); size varies per orientation
            filterButton.trailingAnchor.constraint(equalTo: menuButton.trailingAnchor),
            filterButton.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 10),

            // Tags view anchored near filter button; its height tracks filter button height
            tagsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tagsView.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -10),
            tagsView.topAnchor.constraint(equalTo: filterButton.topAnchor),
            tagsView.heightAnchor.constraint(equalTo: filterButton.heightAnchor),

            // AND/OR Toggle Button
            filterModeButton.trailingAnchor.constraint(equalTo: tagsView.trailingAnchor),
            filterModeButton.bottomAnchor.constraint(equalTo: tagsView.topAnchor, constant: 1),
            filterModeButton.heightAnchor.constraint(equalToConstant: 22),
            filterModeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // Build Label
            buildLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -35),
            buildLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            buildLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1),
            buildLabel.heightAnchor.constraint(equalToConstant: 30),

            // Version Label
            versionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 35),
            versionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25),
            versionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1),
            versionLabel.heightAnchor.constraint(equalToConstant: 30),

            // Now Playing View
            playlistManager.nowPlayingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playlistManager.nowPlayingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            playlistManager.nowPlayingView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 15),
            nowPlayingHeightEq,
            nowPlayingHeightMin,

            // Playlist Control View
            playlistManager.playlistControlView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playlistManager.playlistControlView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            playlistManager.playlistControlView.topAnchor.constraint(equalTo: playlistManager.nowPlayingView.bottomAnchor),

            // Playlist Library View
            playlistManager.playlistTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playlistManager.playlistTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playlistManager.playlistTableView.topAnchor.constraint(equalTo: playlistManager.playlistControlView.bottomAnchor),
            playlistManager.playlistTableView.bottomAnchor.constraint(equalTo: versionLabel.topAnchor),

            // Filter Picker View fills screen
            filterPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterPickerView.topAnchor.constraint(equalTo: view.topAnchor),
            filterPickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        // Portrait-specific sizes
        let portraitLogoH = logoView.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.1)
        portraitLogoH.priority = UILayoutPriority(999)
        let portraitLogoHMax = logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 60)
        let portraitLogoHMin = logoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        let portraitFilterW = filterButton.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.15)
        portraitFilterW.priority = UILayoutPriority(999)
        let portraitFilterWMax = filterButton.widthAnchor.constraint(lessThanOrEqualToConstant: 80)

        let portraitFilterH = filterButton.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.15)
        portraitFilterH.priority = UILayoutPriority(999)
        let portraitFilterHMax = filterButton.heightAnchor.constraint(lessThanOrEqualToConstant: 80)
        let portraitFilterMin = filterButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        portraitConstraints = [
            portraitLogoH,
            portraitLogoHMax,
            portraitLogoHMin,
            portraitFilterW,
            portraitFilterWMax,
            portraitFilterH,
            portraitFilterHMax,
            portraitFilterMin
        ]

        // Landscape-specific sizes
        // - Make logoView smaller
        // - Make filterButton height 115 pt (and tie width to height)
        let landscapeLogoH = logoView.heightAnchor.constraint(equalToConstant: 40)
        let landscapeFilterH = filterButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.125)
        let landscapeFilterW = filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor)
        landscapeConstraints = [
            landscapeLogoH,
            landscapeFilterH,
            landscapeFilterW
        ]

        // Activate common constraints and the appropriate orientation set
        NSLayoutConstraint.activate(commonConstraints)

        playlistControlHeightConstraint = playlistManager.playlistControlView.heightAnchor.constraint(equalToConstant: playlistControlBaseHeight)
        playlistControlHeightConstraint.isActive = true

        applyConstraints(for: traitCollection)
    }
    
    // MARK: - Button Actions
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
    
    @objc private func toggleFilterMode() {
        print("Toggle filter logic")
        isAndMode.toggle()
        filterModeButton.setTitle(isAndMode ? "AND" : "OR", for: .normal)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()  // Haptic tap
        // Minimal pulse + shadow emphasis
        UIView.animate(withDuration: 0.12, animations: {
            self.filterModeButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.filterModeButton.layer.shadowOpacity = 0.18
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                self.filterModeButton.transform = .identity
                self.filterModeButton.layer.shadowOpacity = 0.12
            }
        }
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
    
    @objc private func handleLyricsToggle(_ note: Notification) {
        guard let info = note.userInfo,
              let isShown = info["isShown"] as? Bool else { return }
        isLyricsShown = isShown
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let shouldExpandLyrics = isLyricsShown && !isLandscape
        playlistControlHeightConstraint.constant = shouldExpandLyrics ? (playlistControlBaseHeight * 2) : playlistControlBaseHeight
        layoutIfInWindow()
    }
    
    func collapsePlaylistControlHeight(animated: Bool = false) {
        playlistControlHeightConstraint.constant =  playlistControlBaseHeight
        layoutIfInWindow(animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .playlistDidUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playlistWillUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playlistControlLyricsToggled, object: nil)
    }
    
}
