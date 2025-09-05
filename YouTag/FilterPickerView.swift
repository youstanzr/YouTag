//
//  FilterPickerView.swift
//  YouTag
//
//  Created by Youstanzr on 3/15/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

typealias FilterType = PlaylistFilters.FilterType

protocol FilterPickerViewDelegate: AnyObject {
    func processNewFilter(type: FilterType, filters: [Any])
}

class FilterPickerView: UIView {

    // MARK: - Properties
    private struct SegmentItem { let type: PlaylistFilters.FilterType; let title: String }
    private var segmentItems: [SegmentItem] = []
    weak var delegate: FilterPickerViewDelegate?
    
    var tagView: YYTTagView!
    // Content height per orientation
    private var contentViewPortraitHeight: NSLayoutConstraint!
    private var contentViewLandscapeHeight: NSLayoutConstraint!
    let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    private let filterSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Tag", "Artist", "Album", "Year", "Length"])
        s.selectedSegmentIndex = 0
        s.setTitleTextAttributes([.font: UIFont(name: "DINCondensed-Bold", size: 20)!, .foregroundColor: UIColor.white], for: .normal)
        s.backgroundColor = GraphicColors.obsidianBlack
        s.selectedSegmentTintColor = GraphicColors.orange
        s.layer.maskedCorners = .init()
        return s
    }()
    private let releaseYrSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Year range", "Exact year"])
        s.selectedSegmentIndex = 0
        s.setTitleTextAttributes([.font: UIFont(name: "DINCondensed-Bold", size: 20)!, .foregroundColor: UIColor.white], for: .normal)
        s.backgroundColor = GraphicColors.obsidianBlack
        s.selectedSegmentTintColor = GraphicColors.orange
        s.layer.maskedCorners = .init()
        return s
    }()
    private let pickerView: UIView = {
        let v = UIView()
        v.backgroundColor = GraphicColors.obsidianBlack
        return v
    }()
    private let closeButton = UIButton()
    private let addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.obsidianBlack
        config.baseForegroundColor = GraphicColors.orange
        config.title = "+"
        config.titleAlignment = .center
        config.attributedTitle = AttributedString("+", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 42)]))
        button.configuration = config
        button.addBorder(side: .top, color: GraphicColors.darkGray, width: 1.0)
        button.configurationUpdateHandler = { button in
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: -5.0, leading: 0.0, bottom: 0.0, trailing: 0.0)
        }
        return button
    }()
    private let rangeSliderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    private let rangeSlider: YYTRangeSlider = {
        let rSlider = YYTRangeSlider(frame: .zero)
        rSlider.trackTintColor = GraphicColors.darkGray
        rSlider.trackHighlightTintColor = GraphicColors.orange
        rSlider.thumbColor = GraphicColors.lightGray
        return rSlider
    }()
    let rangeSliderLowerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "00:00"
        lbl.textColor = GraphicColors.cloudWhite
        lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 22)
        lbl.textAlignment = .left
        return lbl
    }()
    let rangeSliderUpperLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "10:00"
        lbl.textColor = GraphicColors.cloudWhite
        lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 22)
        lbl.textAlignment = .right
        return lbl
    }()
    var scope: [Song]
    fileprivate var tagViewDefaultTopAnchor: NSLayoutConstraint?
    fileprivate var tagViewWithSegmentTopAnchor: NSLayoutConstraint?
    fileprivate var rangeSliderViewDefaultTopAnchor: NSLayoutConstraint?
    fileprivate var rangeSliderViewWithSegmentTopAnchor: NSLayoutConstraint?

    // MARK: - Initialization
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        scope = []
        super.init(frame: UIScreen.main.bounds)
        setupView()
        setupConstraints()
        configureActions()
    }

    // MARK: - Setup
    private func setupView() {
        self.isHidden = true
        self.backgroundColor = GraphicColors.obsidianBlack.withAlphaComponent(0.85)

        // Close Button
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        self.addSubview(closeButton)

        // Content View
        self.addSubview(contentView)
        contentView.addSubview(filterSegment)
        contentView.addSubview(pickerView)
        contentView.addSubview(addButton)

        // Picker View
        pickerView.addSubview(releaseYrSegment)
        pickerView.addSubview(rangeSliderView)

        // Tag View
        let style = TagViewStyle(
            isAddEnabled: false,
            isMultiSelection: true,
            isDeleteEnabled: false,
            showsBorder: false,
            cellFont: UIFont(name: "DINCondensed-Bold", size: 16)!,
            overflow: .scrollable,
            verticalPadding: 5
        )
        tagView = YYTTagView(
            frame: .zero,
            tagsList: [],
            suggestionDataSource: nil,
            style: style
        )
        pickerView.addSubview(tagView)

        // Range Slider View
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        rangeSliderView.addSubview(rangeSlider)
        rangeSliderView.addSubview(rangeSliderLowerLabel)
        rangeSliderView.addSubview(rangeSliderUpperLabel)
    }

    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor),
            closeButton.widthAnchor.constraint(equalTo: self.widthAnchor),
            closeButton.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])

        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        // Portrait vs. landscape heights
        contentViewPortraitHeight = contentView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.40)
        contentViewLandscapeHeight = contentView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.60)
        if traitCollection.verticalSizeClass == .compact {
            contentViewLandscapeHeight.isActive = true
        } else {
            contentViewPortraitHeight.isActive = true
        }

        filterSegment.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            filterSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterSegment.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15)
        ])

        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -2.5),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 2.5),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        addButton.applyStandardBottomBarHeight(70)

        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: filterSegment.bottomAnchor),
            pickerView.bottomAnchor.constraint(equalTo: addButton.topAnchor)
        ])

        releaseYrSegment.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            releaseYrSegment.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 5),
            releaseYrSegment.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -5),
            releaseYrSegment.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5),
            releaseYrSegment.heightAnchor.constraint(equalTo: pickerView.heightAnchor, multiplier: 0.15)
        ])

        tagView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagView.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 5),
            tagView.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -5),
            tagView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: -5)
        ])
        tagViewDefaultTopAnchor = tagView.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5)
        tagViewWithSegmentTopAnchor = tagView.topAnchor.constraint(equalTo: releaseYrSegment.bottomAnchor, constant: 5)
        tagViewDefaultTopAnchor?.isActive = true
        tagViewWithSegmentTopAnchor?.isActive = false

        rangeSliderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rangeSliderView.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 15),
            rangeSliderView.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -15),
            rangeSliderView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: -5)
        ])
        rangeSliderViewDefaultTopAnchor = rangeSliderView.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5)
        rangeSliderViewWithSegmentTopAnchor = rangeSliderView.topAnchor.constraint(equalTo: releaseYrSegment.bottomAnchor, constant: 5)
        rangeSliderViewDefaultTopAnchor?.isActive = true
        rangeSliderViewWithSegmentTopAnchor?.isActive = false

        rangeSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rangeSlider.leadingAnchor.constraint(equalTo: rangeSliderView.leadingAnchor, constant: 5),
            rangeSlider.trailingAnchor.constraint(equalTo: rangeSliderView.trailingAnchor, constant: -5),
            rangeSlider.heightAnchor.constraint(equalToConstant: 30),
            rangeSlider.centerYAnchor.constraint(equalTo: rangeSliderView.centerYAnchor)
        ])

        rangeSliderLowerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rangeSliderLowerLabel.leadingAnchor.constraint(equalTo: rangeSlider.leadingAnchor),
            rangeSliderLowerLabel.widthAnchor.constraint(equalTo: rangeSliderView.widthAnchor, multiplier: 0.25),
            rangeSliderLowerLabel.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor),
            rangeSliderLowerLabel.heightAnchor.constraint(equalTo: rangeSliderView.heightAnchor, multiplier: 0.15)
        ])

        rangeSliderUpperLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rangeSliderUpperLabel.trailingAnchor.constraint(equalTo: rangeSlider.trailingAnchor),
            rangeSliderUpperLabel.widthAnchor.constraint(equalTo: rangeSliderView.widthAnchor, multiplier: 0.25),
            rangeSliderUpperLabel.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor),
            rangeSliderUpperLabel.heightAnchor.constraint(equalTo: rangeSliderView.heightAnchor, multiplier: 0.15)
        ])
    }

    private func applyContentHeightForTraits() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        contentViewPortraitHeight?.isActive = !isLandscape
        contentViewLandscapeHeight?.isActive = isLandscape
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyContentHeightForTraits()
    }

    private func configureActions() {
        filterSegment.addTarget(self, action: #selector(filterValueChanged(sender:)), for: .valueChanged)
        releaseYrSegment.addTarget(self, action: #selector(releaseYrValueChanged(_:)), for: .valueChanged)
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
    }

    private func rebuildSegments() {
        scope = LibraryManager.shared.getFilteredSongs(with: PlaylistManager.shared.playlistFilters, mode: PlaylistManager.shared.filterLogic)

        func filtered(_ values: [String], _ t: PlaylistFilters.FilterType) -> [String] {
            removeActive(values, for: t)
        }

        // Build candidate lists per tab
        let tags    = filtered(LibraryManager.shared.getAllDistinctValues(for: "tags", in: scope), .tag)
        let artists = filtered(LibraryManager.shared.getAllDistinctValues(for: "artists", in: scope), .artist)
        let albums  = filtered(LibraryManager.shared.getAllDistinctValues(for: "album", in: scope), .album)
        let years   = filtered(LibraryManager.shared.getAllDistinctValues(for: "releaseYear", in: scope), .releaseYear)
        let dmin    = LibraryManager.shared.getDuration(.min, in: scope)
        let dmax    = LibraryManager.shared.getDuration(.max, in: scope)
        let ymin    = LibraryManager.shared.getReleaseYear(.min, in: scope)
        let ymax    = LibraryManager.shared.getReleaseYear(.max, in: scope)

        var items: [SegmentItem] = []
        if !tags.isEmpty                 { items.append(.init(type: .tag,          title: "Tag")) }
        if !artists.isEmpty              { items.append(.init(type: .artist,       title: "Artist")) }
        if !albums.isEmpty               { items.append(.init(type: .album,        title: "Album")) }
        if (!years.isEmpty) || (ymin < ymax) { items.append(.init(type: .releaseYear, title: "Year")) }
        if dmin < dmax                   { items.append(.init(type: .duration,     title: "Length")) }

        segmentItems = items

        // Update segmented control to show only non-empty tabs
        filterSegment.removeAllSegments()
        for (idx, it) in items.enumerated() {
            filterSegment.insertSegment(withTitle: it.title, at: idx, animated: false)
        }
        filterSegment.selectedSegmentIndex = items.isEmpty ? UISegmentedControl.noSegment : 0
    }

    // MARK: - Actions
    @objc private func close() {
        self.isHidden = true
    }

    @objc func add() {
        print("Add button pressed")
        guard !segmentItems.isEmpty,
              filterSegment.selectedSegmentIndex >= 0,
              filterSegment.selectedSegmentIndex < segmentItems.count else { return }

        let item = segmentItems[filterSegment.selectedSegmentIndex]
        switch item.type {
        case .tag:
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: .tag, filters: tagView.selectedTagList)
            }
        case .artist:
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: .artist, filters: tagView.selectedTagList)
            }
        case .album:
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: .album, filters: tagView.selectedTagList)
            }
        case .releaseYear:
            if releaseYrSegment.selectedSegmentIndex == 0 {
                // Year range
                if Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero)) != Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero)) {
                    let lowerValue = Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero))
                    let upperValue = Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero))
                    delegate?.processNewFilter(type: .releaseYearRange, filters: [lowerValue, upperValue])
                }
            } else {
                // Exact year(s)
                if !tagView.selectedTagList.isEmpty {
                    delegate?.processNewFilter(type: .releaseYear, filters: tagView.selectedTagList)
                }
            }
        case .duration:
            if Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero)) != Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero)) {
                let lowerValue = TimeInterval(rangeSlider.lowerValue).rounded(.toNearestOrAwayFromZero)
                let upperValue = TimeInterval(rangeSlider.upperValue).rounded(.toNearestOrAwayFromZero)
                delegate?.processNewFilter(type: .duration, filters: [lowerValue, upperValue])
            }
        case .releaseYearRange:
            // Not presented as a separate tab; handled via .releaseYear UI
            break
        }

        close()
        tagView.deselectAllTags()
    }
    
    func show(animated: Bool) {
        print("Show tag picker view")
        self.isHidden = false
        rebuildSegments()
        if filterSegment.selectedSegmentIndex == UISegmentedControl.noSegment {
            // Nothing to show; keep picker empty
        } else {
            self.filterValueChanged(sender: filterSegment)
        }
        applyContentHeightForTraits()
        if animated {
            self.contentView.frame.origin.y = UIScreen.main.bounds.height
            UIView.animate(withDuration: 0.2, animations: {
                self.contentView.frame.origin.y = UIScreen.main.bounds.height - self.contentView.frame.height
            }, completion: nil)
        }
    }
    
    @objc func filterValueChanged(sender: UISegmentedControl) {
        tagView.isHidden = true
        releaseYrSegment.isHidden = true
        rangeSliderView.isHidden = true

        tagViewWithSegmentTopAnchor?.isActive = false
        tagViewDefaultTopAnchor?.isActive = true
        rangeSliderViewWithSegmentTopAnchor?.isActive = false
        rangeSliderViewDefaultTopAnchor?.isActive = true

        guard !segmentItems.isEmpty,
              sender.selectedSegmentIndex >= 0,
              sender.selectedSegmentIndex < segmentItems.count else {
            tagView.collectionView.reloadData()
            return
        }

        let item = segmentItems[sender.selectedSegmentIndex]

        switch item.type {
        case .tag:
            tagView.isHidden = false
            let all = LibraryManager.shared.getAllDistinctValues(for: "tags", in: scope)
            tagView.tagsList = removeActive(all, for: .tag)

        case .artist:
            tagView.isHidden = false
            let all = LibraryManager.shared.getAllDistinctValues(for: "artists", in: scope)
            tagView.tagsList = removeActive(all, for: .artist)

        case .album:
            tagView.isHidden = false
            let all = LibraryManager.shared.getAllDistinctValues(for: "album", in: scope)
            tagView.tagsList = removeActive(all, for: .album)

        case .releaseYear:
            let ymin = LibraryManager.shared.getReleaseYear(.min, in: scope)
            let ymax = LibraryManager.shared.getReleaseYear(.max, in: scope)
            releaseYrSegment.isHidden = false
            releaseYrValueChanged(releaseYrSegment)

            // Configure slider bounds + labels
            rangeSlider.minimumValue = CGFloat(ymin)
            rangeSlider.maximumValue = CGFloat(ymax)
            rangeSlider.lowerValue = rangeSlider.minimumValue
            rangeSlider.upperValue = rangeSlider.maximumValue
            rangeSliderLowerLabel.text = String(ymin)
            rangeSliderUpperLabel.text = String(ymax)

        case .duration:
            let dmin = LibraryManager.shared.getDuration(.min, in: scope)
            let dmax = LibraryManager.shared.getDuration(.max, in: scope)
            rangeSliderView.isHidden = false
            rangeSlider.minimumValue = CGFloat(dmin)
            rangeSlider.maximumValue = CGFloat(dmax)
            rangeSlider.lowerValue = rangeSlider.minimumValue
            rangeSlider.upperValue = rangeSlider.maximumValue
            rangeSliderLowerLabel.text = dmin.stringFromTimeInterval()
            rangeSliderUpperLabel.text = dmax.stringFromTimeInterval()
        case .releaseYearRange:
            // Not presented as a separate tab; handled via .releaseYear UI
            break
        }

        tagView.collectionView.reloadData()
        self.layoutIfNeeded()
        tagView.collectionView.setContentOffset(.zero, animated: false)
    }
    
    @objc func releaseYrValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 { // Year range
            tagView.isHidden = true
            rangeSliderView.isHidden = false
            rangeSliderViewDefaultTopAnchor?.isActive = false
            rangeSliderViewWithSegmentTopAnchor?.isActive = true
            rangeSlider.minimumValue = CGFloat(LibraryManager.shared.getReleaseYear(.min, in: scope))
            rangeSlider.maximumValue = CGFloat(LibraryManager.shared.getReleaseYear(.max, in: scope))
            rangeSlider.lowerValue = rangeSlider.minimumValue
            rangeSlider.upperValue = rangeSlider.maximumValue
            rangeSliderLowerLabel.text = String(LibraryManager.shared.getReleaseYear(.min, in: scope))
            rangeSliderUpperLabel.text = String(LibraryManager.shared.getReleaseYear(.max, in: scope))
        } else { // Exact year
            rangeSliderView.isHidden = true
            tagView.isHidden = false
            let all = LibraryManager.shared.getAllDistinctValues(for: "releaseYear", in: scope)
            tagView.tagsList = removeActive(all, for: .releaseYear)
            tagViewDefaultTopAnchor?.isActive = false
            tagViewWithSegmentTopAnchor?.isActive = true
        }
        tagView.collectionView.reloadData()
        self.layoutIfNeeded()
    }

    @objc func rangeSliderValueChanged(_ sender: YYTRangeSlider) {
        guard !segmentItems.isEmpty,
              filterSegment.selectedSegmentIndex >= 0,
              filterSegment.selectedSegmentIndex < segmentItems.count else { return }

        let type = segmentItems[filterSegment.selectedSegmentIndex].type
        switch type {
        case .releaseYear:
            // When on Year tab and in range mode, show integer years
            rangeSliderLowerLabel.text = String(Int(sender.lowerValue.rounded(.toNearestOrAwayFromZero)))
            rangeSliderUpperLabel.text = String(Int(sender.upperValue.rounded(.toNearestOrAwayFromZero)))
        case .duration:
            // When on Length tab, show time strings
            rangeSliderLowerLabel.text = TimeInterval(sender.lowerValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
            rangeSliderUpperLabel.text = TimeInterval(sender.upperValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
        case .tag, .artist, .album, .releaseYearRange:
            break
        }
    }
    
    private func removeActive(_ values: [String], for type: PlaylistFilters.FilterType) -> [String] {
        let active = Set(
            PlaylistManager.shared.playlistFilters
                .getFilters()
                .filter { $0[0] == type.rawValue }
                .map { $0[1] }
        )
        return values.filter { !active.contains($0) }
    }
}
