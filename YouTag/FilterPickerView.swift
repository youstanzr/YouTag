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
    weak var delegate: FilterPickerViewDelegate?
    
    var tagView: YYTTagView!
    let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    private let filterSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Tag", "Artist", "Album", "Year", "Length"])
        s.selectedSegmentIndex = 0
        s.setTitleTextAttributes([.font: UIFont(name: "DINCondensed-Bold", size: 20)!, .foregroundColor: UIColor.white], for: .normal)
        s.backgroundColor = GraphicColors.charcoalBlack
        s.selectedSegmentTintColor = GraphicColors.orange
        s.layer.maskedCorners = .init()
        return s
    }()
    private let releaseYrSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Year range", "Exact year"])
        s.selectedSegmentIndex = 0
        s.setTitleTextAttributes([.font: UIFont(name: "DINCondensed-Bold", size: 20)!, .foregroundColor: UIColor.white], for: .normal)
        s.backgroundColor = GraphicColors.charcoalBlack
        s.selectedSegmentTintColor = GraphicColors.orange
        s.layer.maskedCorners = .init()
        return s
    }()
    private let pickerView: UIView = {
        let v = UIView()
        v.backgroundColor = GraphicColors.charcoalBlack
        return v
    }()
    private let closeButton = UIButton()
    private let addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.charcoalBlack
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
    fileprivate var tagViewDefaultTopAnchor: NSLayoutConstraint?
    fileprivate var tagViewWithSegmentTopAnchor: NSLayoutConstraint?
    fileprivate var rangeSliderViewDefaultTopAnchor: NSLayoutConstraint?
    fileprivate var rangeSliderViewWithSegmentTopAnchor: NSLayoutConstraint?

    // MARK: - Initialization
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        setupView()
        setupConstraints()
        configureActions()
    }

    // MARK: - Setup
    private func setupView() {
        self.isHidden = true
        self.backgroundColor = GraphicColors.charcoalBlack.withAlphaComponent(0.85)

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
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.4)
        ])

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
            addButton.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.09)
        ])

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

    private func configureActions() {
        filterSegment.addTarget(self, action: #selector(filterValueChanged(sender:)), for: .valueChanged)
        releaseYrSegment.addTarget(self, action: #selector(releaseYrValueChanged(_:)), for: .valueChanged)
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func close() {
        self.isHidden = true
    }

    @objc func add() {
        print("Add button pressed")
        switch filterSegment.selectedSegmentIndex {
        case 0: // Tags filter
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: FilterType.tag, filters: tagView.selectedTagList)
            }
        case 1: // Artists filter
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: FilterType.artist, filters: tagView.selectedTagList)
            }
        case 2: // Album filter
            if !tagView.selectedTagList.isEmpty {
                delegate?.processNewFilter(type: FilterType.album, filters: tagView.selectedTagList)
            }
        case 3: // Release year filter
            if releaseYrSegment.selectedSegmentIndex == 0, // Year range
               Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero)) != Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero)) {
                let lowerValue = Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero))
                let upperValue = Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero))
                delegate?.processNewFilter(type: FilterType.releaseYearRange, filters: [lowerValue, upperValue])
            } else if releaseYrSegment.selectedSegmentIndex == 1, !tagView.selectedTagList.isEmpty { // Exact year
                delegate?.processNewFilter(type: FilterType.releaseYear, filters: tagView.selectedTagList)
            }
        case 4: // Duration filter
            if Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero)) != Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero)) {
                let lowerValue = TimeInterval(rangeSlider.lowerValue).rounded(.toNearestOrAwayFromZero)
                let upperValue = TimeInterval(rangeSlider.upperValue).rounded(.toNearestOrAwayFromZero)
                delegate?.processNewFilter(type: FilterType.duration, filters: [lowerValue, upperValue])
            }
        default:
            break
        }
        close() // Close the picker view
        tagView.deselectAllTags()
    }

    @objc func filterValueChanged(sender: UISegmentedControl) {
        tagView.isHidden = true
        releaseYrSegment.isHidden = true
        rangeSliderView.isHidden = true

        tagViewWithSegmentTopAnchor?.isActive = false
        tagViewDefaultTopAnchor?.isActive = true
        rangeSliderViewWithSegmentTopAnchor?.isActive = false
        rangeSliderViewDefaultTopAnchor?.isActive = true

        switch sender.selectedSegmentIndex {
        case 0: // Tags
            tagView.isHidden = false
            tagView.tagsList = LibraryManager.shared.getAllDistinctValues(for: "tags")
        case 1: // Artists
            tagView.isHidden = false
            tagView.tagsList = LibraryManager.shared.getAllDistinctValues(for: "artists")
        case 2: // Albums
            tagView.isHidden = false
            tagView.tagsList = LibraryManager.shared.getAllDistinctValues(for: "album")
        case 3: // Release Year
            releaseYrSegment.isHidden = false
            releaseYrValueChanged(releaseYrSegment)
        case 4: // Duration
            rangeSliderView.isHidden = false
            rangeSlider.minimumValue = CGFloat(LibraryManager.shared.getDuration(.min))
            rangeSlider.maximumValue = CGFloat(LibraryManager.shared.getDuration(.max))
            rangeSlider.lowerValue = rangeSlider.minimumValue
            rangeSlider.upperValue = rangeSlider.maximumValue
            rangeSliderLowerLabel.text = LibraryManager.shared.getDuration(.min).stringFromTimeInterval()
            rangeSliderUpperLabel.text = LibraryManager.shared.getDuration(.max).stringFromTimeInterval()
        default:
            break
        }
        tagView.collectionView.reloadData()
        self.layoutIfNeeded()
        tagView.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
    }
    
    @objc func releaseYrValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 { // Year range
            tagView.isHidden = true
            rangeSliderView.isHidden = false
            rangeSliderViewDefaultTopAnchor?.isActive = false
            rangeSliderViewWithSegmentTopAnchor?.isActive = true
            rangeSlider.minimumValue = CGFloat(LibraryManager.shared.getReleaseYear(.min))
            rangeSlider.maximumValue = CGFloat(LibraryManager.shared.getReleaseYear(.max))
            rangeSlider.lowerValue = rangeSlider.minimumValue
            rangeSlider.upperValue = rangeSlider.maximumValue
            rangeSliderLowerLabel.text = String(LibraryManager.shared.getReleaseYear(.min))
            rangeSliderUpperLabel.text = String(LibraryManager.shared.getReleaseYear(.max))
        } else { // Exact year
            rangeSliderView.isHidden = true
            tagView.isHidden = false
            tagView.tagsList = LibraryManager.shared.getAllDistinctValues(for: "releaseYear")
            tagViewDefaultTopAnchor?.isActive = false
            tagViewWithSegmentTopAnchor?.isActive = true
        }
        tagView.collectionView.reloadData()
        self.layoutIfNeeded()
    }

    @objc func rangeSliderValueChanged(_ sender: YYTRangeSlider) {
        if filterSegment.selectedSegmentIndex == 3 { // Release year
            rangeSliderLowerLabel.text = String(Int(sender.lowerValue.rounded(.toNearestOrAwayFromZero)))
            rangeSliderUpperLabel.text = String(Int(sender.upperValue.rounded(.toNearestOrAwayFromZero)))
        } else { // Duration
            rangeSliderLowerLabel.text = TimeInterval(sender.lowerValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
            rangeSliderUpperLabel.text = TimeInterval(sender.upperValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
        }
    }
    func show(animated: Bool) {
        print("Show tag picker view")
        self.isHidden = false
        self.filterValueChanged(sender: filterSegment)
        if animated {
            self.contentView.frame.origin.y = UIScreen.main.bounds.height
            UIView.animate(withDuration: 0.2, animations: {
                self.contentView.frame.origin.y = UIScreen.main.bounds.height - self.contentView.frame.height
            }, completion: nil)
        }
    }
    
}
