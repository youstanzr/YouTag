//
//  FilterPickerView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/15/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

protocol FilterPickerViewDelegate: class {
	func processNewFilter(type: String, filters: NSMutableArray)
}

class FilterPickerView: UIView {

	weak var delegate: FilterPickerViewDelegate?
	
	var tagView: YYTTagView!
	let contentView: UIView = {
		let v = UIView()
		v.backgroundColor = .clear
		return v
	}()
	let filterSegment: UISegmentedControl = {
		let s = UISegmentedControl(items: ["Tag","Artist","Album","Year","Length"])
		s.selectedSegmentIndex = 0
		s.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "DINCondensed-Bold", size: 20)!], for: .normal)
		s.backgroundColor = GraphicColors.backgroundWhite
		if #available(iOS 13.0, *) {
			s.selectedSegmentTintColor = GraphicColors.orange
			s.layer.maskedCorners = .init()
		} else {
			s.layer.cornerRadius = 0
		}
		return s
	}()
	let releaseYrSegment: UISegmentedControl = {
		let s = UISegmentedControl(items: ["Year range", "Exact year"])
		s.selectedSegmentIndex = 0
		s.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "DINCondensed-Bold", size: 20)!], for: .normal)
		s.backgroundColor = GraphicColors.backgroundWhite
		if #available(iOS 13.0, *) {
			s.selectedSegmentTintColor = GraphicColors.orange
			s.layer.maskedCorners = .init()
		} else {
			s.layer.cornerRadius = 0
		}
		return s
	}()
	let pickerView: UIView = {
		let v = UIView()
		v.backgroundColor = GraphicColors.backgroundWhite
		return v
	}()
	let closeButton = UIButton()
	let addButton: UIButton = {
		let button = UIButton()
		button.backgroundColor = GraphicColors.green
		button.titleLabel?.textColor = .white
		button.titleLabel?.font = .boldSystemFont(ofSize: 38)
		button.setTitle("+", for: .normal)
		button.contentVerticalAlignment = .top
		button.titleEdgeInsets = UIEdgeInsets(top: -5.0, left: 0.0, bottom: 0.0, right: 0.0)
		return button
	}()
	let rangeSliderView: UIView = {
		let v = UIView()
		v.backgroundColor = .clear
		return v
	}()
	let rangeSlider: YYTRangeSlider = {
		let rSlider = YYTRangeSlider(frame: .zero)
		rSlider.trackTintColor = GraphicColors.trackGray
		rSlider.trackHighlightTintColor = GraphicColors.orange
		rSlider.thumbColor = .lightGray
		return rSlider
	}()
	let rangeSliderLowerLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "00:00"
		lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 22)
		lbl.textAlignment = .left
		return lbl
	}()
	let rangeSliderUpperLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "10:00"
		lbl.font = UIFont.init(name: "DINCondensed-Bold", size: 22)
		lbl.textAlignment = .right
		return lbl
	}()
	fileprivate var tagViewDefaultTopAnchor: NSLayoutConstraint?
	fileprivate var tagViewWithSegmentTopAnchor: NSLayoutConstraint?
	fileprivate var rangeSliderViewDefaultTopAnchor: NSLayoutConstraint?
	fileprivate var rangeSliderViewWithSegmentTopAnchor: NSLayoutConstraint?

	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	init() {
		super.init(frame: UIScreen.main.bounds)
		self.isHidden = true
		self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
		
		self.addSubview(closeButton)
		closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
		closeButton.translatesAutoresizingMaskIntoConstraints = false
		closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
		closeButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		closeButton.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
		closeButton.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

		self.addSubview(contentView)
		contentView.translatesAutoresizingMaskIntoConstraints = false
		contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
		contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
		contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		contentView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.36).isActive = true

		filterSegment.addTarget(self, action: #selector(filterValueChanged(sender:)), for: .valueChanged)
		contentView.addSubview(filterSegment)
		filterSegment.translatesAutoresizingMaskIntoConstraints = false
		filterSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		filterSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
		filterSegment.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
		filterSegment.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15).isActive = true

		releaseYrSegment.isHidden = true
		releaseYrSegment.addTarget(self, action: #selector(releaseYrValueChanged(_:)), for: .valueChanged)
		pickerView.addSubview(releaseYrSegment)
		releaseYrSegment.translatesAutoresizingMaskIntoConstraints = false
		releaseYrSegment.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 5).isActive = true
		releaseYrSegment.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -5).isActive = true
		releaseYrSegment.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5).isActive = true
		releaseYrSegment.heightAnchor.constraint(equalTo: pickerView.heightAnchor, multiplier: 0.15).isActive = true

		contentView.addSubview(addButton)
		addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
		addButton.translatesAutoresizingMaskIntoConstraints = false
		addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
		addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
		addButton.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.225).isActive = true
		
		contentView.addSubview(pickerView)
		pickerView.translatesAutoresizingMaskIntoConstraints = false
		pickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
		pickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		pickerView.topAnchor.constraint(equalTo: filterSegment.bottomAnchor).isActive = true
		pickerView.bottomAnchor.constraint(equalTo: addButton.topAnchor).isActive = true
		
		tagView = YYTTagView(frame: .zero, tagsList: LibraryManager.getAll(.tags), isAddEnabled: false, isMultiSelection: true, isDeleteEnabled: false)
		pickerView.addSubview(tagView)
		tagView.translatesAutoresizingMaskIntoConstraints = false
		tagView.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 5).isActive = true
		tagView.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -5).isActive = true
		tagView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: -5).isActive = true
		tagViewDefaultTopAnchor = tagView.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5)
		tagViewWithSegmentTopAnchor = tagView.topAnchor.constraint(equalTo: releaseYrSegment.bottomAnchor, constant: 5)
		tagViewDefaultTopAnchor?.isActive = true
		tagViewWithSegmentTopAnchor?.isActive = false
		
		rangeSliderView.isHidden = true
		pickerView.addSubview(rangeSliderView)
		rangeSliderView.translatesAutoresizingMaskIntoConstraints = false
		rangeSliderView.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 15).isActive = true
		rangeSliderView.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -15).isActive = true
		rangeSliderView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: -5).isActive = true
		rangeSliderViewDefaultTopAnchor = rangeSliderView.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5)
		rangeSliderViewWithSegmentTopAnchor = rangeSliderView.topAnchor.constraint(equalTo: releaseYrSegment.bottomAnchor, constant: 5)
		rangeSliderViewDefaultTopAnchor?.isActive = true
		rangeSliderViewWithSegmentTopAnchor?.isActive = false

		rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
		rangeSliderView.addSubview(rangeSlider)
		rangeSlider.translatesAutoresizingMaskIntoConstraints = false
		rangeSlider.leadingAnchor.constraint(equalTo: rangeSliderView.leadingAnchor, constant: 5).isActive = true
		rangeSlider.trailingAnchor.constraint(equalTo: rangeSliderView.trailingAnchor, constant: -5).isActive = true
		rangeSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
		rangeSlider.centerYAnchor.constraint(equalTo: rangeSliderView.centerYAnchor).isActive = true
		
		rangeSliderView.addSubview(rangeSliderLowerLabel)
		rangeSliderLowerLabel.translatesAutoresizingMaskIntoConstraints = false
		rangeSliderLowerLabel.leadingAnchor.constraint(equalTo: rangeSlider.leadingAnchor).isActive = true
		rangeSliderLowerLabel.widthAnchor.constraint(equalTo: rangeSliderView.widthAnchor, multiplier: 0.25).isActive = true
		rangeSliderLowerLabel.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor).isActive = true
		rangeSliderLowerLabel.heightAnchor.constraint(equalTo: rangeSliderView.heightAnchor, multiplier: 0.15).isActive = true

		rangeSliderView.addSubview(rangeSliderUpperLabel)
		rangeSliderUpperLabel.translatesAutoresizingMaskIntoConstraints = false
		rangeSliderUpperLabel.trailingAnchor.constraint(equalTo: rangeSlider.trailingAnchor).isActive = true
		rangeSliderUpperLabel.widthAnchor.constraint(equalTo: rangeSliderView.widthAnchor, multiplier: 0.25).isActive = true
		rangeSliderUpperLabel.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor).isActive = true
		rangeSliderUpperLabel.heightAnchor.constraint(equalTo: rangeSliderView.heightAnchor, multiplier: 0.15).isActive = true
	}
		
	func show(withAnimation isAnimated: Bool) {
		print("Show tag picker view")
		self.isHidden = false
		self.filterValueChanged(sender: filterSegment)
		if isAnimated {
			self.contentView.frame.origin.y = UIScreen.main.bounds.height
			UIView.animate(withDuration: 0.2, animations: {
				self.contentView.frame.origin.y = UIScreen.main.bounds.height - self.contentView.frame.height
			}, completion: nil)
		}
	}
	
	@objc func close() {
		print("Close button pressed")
		self.isHidden = true
	}
	
	@objc func add() {
		print("Add button pressed")
		if filterSegment.selectedSegmentIndex == 0 && tagView.selectedTagList.count > 0 {
			// selected tags filter
			delegate?.processNewFilter(type: "tags", filters: tagView.selectedTagList)
		} else if filterSegment.selectedSegmentIndex == 1 && tagView.selectedTagList.count > 0 {
			// selected artists filter
			delegate?.processNewFilter(type: "artists", filters: tagView.selectedTagList)
		} else if filterSegment.selectedSegmentIndex == 2 && tagView.selectedTagList.count > 0 {
			// selected album filter
			delegate?.processNewFilter(type: "album", filters: tagView.selectedTagList)
		} else if filterSegment.selectedSegmentIndex == 3 && releaseYrSegment.selectedSegmentIndex == 0 {
			// selected year range filter
			delegate?.processNewFilter(type: "releaseYearRange",
									   filters: NSMutableArray(objects: Int(rangeSlider.lowerValue.rounded(.toNearestOrAwayFromZero))
										, Int(rangeSlider.upperValue.rounded(.toNearestOrAwayFromZero))))
		} else if filterSegment.selectedSegmentIndex == 3 && releaseYrSegment.selectedSegmentIndex == 1 && tagView.selectedTagList.count > 0 {
			// selected exact year filter
			delegate?.processNewFilter(type: "releaseYear", filters: tagView.selectedTagList)
		} else if filterSegment.selectedSegmentIndex == 4 {
			// selected duration filter
			delegate?.processNewFilter(type: "duration",
									   filters: NSMutableArray(objects: TimeInterval(rangeSlider.lowerValue).rounded(.toNearestOrAwayFromZero)
										, TimeInterval(rangeSlider.upperValue).rounded(.toNearestOrAwayFromZero)))
		}
		self.tagView.deselectAllItems()
		self.isHidden = true
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
			case 0:
				tagView.isHidden = false
				tagView.tagsList = LibraryManager.getAll(.tags)
				break
			case 1:
				tagView.isHidden = false
				tagView.tagsList = LibraryManager.getAll(.artists)
				break
			case 2:
				tagView.isHidden = false
				tagView.tagsList = LibraryManager.getAll(.album)
				break
			case 3:
				releaseYrSegment.isHidden = false
				releaseYrValueChanged(releaseYrSegment)
				break
			case 4:
				rangeSliderView.isHidden = false
				rangeSlider.minimumValue = CGFloat(LibraryManager.getDuration(.min))
				rangeSlider.maximumValue = CGFloat(LibraryManager.getDuration(.max))
				rangeSlider.lowerValue = rangeSlider.minimumValue
				rangeSlider.upperValue = rangeSlider.maximumValue
				rangeSliderLowerLabel.text = LibraryManager.getDuration(.min).stringFromTimeInterval()
				rangeSliderUpperLabel.text = LibraryManager.getDuration(.max).stringFromTimeInterval()
				break
			default:
				break
		}
		tagView.reloadData()
		self.layoutIfNeeded()
	}

	@objc func releaseYrValueChanged(_ sender: UISegmentedControl) {
		if sender.selectedSegmentIndex == 0 {
			tagView.isHidden = true
			rangeSliderView.isHidden = false
			rangeSliderViewDefaultTopAnchor?.isActive = false
			rangeSliderViewWithSegmentTopAnchor?.isActive = true
			rangeSlider.minimumValue = CGFloat(LibraryManager.getReleaseYear(.min))
			rangeSlider.maximumValue = CGFloat(LibraryManager.getReleaseYear(.max))
			rangeSlider.lowerValue = rangeSlider.minimumValue
			rangeSlider.upperValue = rangeSlider.maximumValue
			rangeSliderLowerLabel.text = String(LibraryManager.getReleaseYear(.min))
			rangeSliderUpperLabel.text = String(LibraryManager.getReleaseYear(.max))
		} else {
			rangeSliderView.isHidden = true
			tagView.isHidden = false
			tagView.tagsList = LibraryManager.getAll(.releaseYear)
			tagViewDefaultTopAnchor?.isActive = false
			tagViewWithSegmentTopAnchor?.isActive = true
		}
		tagView.reloadData()
		self.layoutIfNeeded()
	}
	
	@objc func rangeSliderValueChanged(_ sender: YYTRangeSlider) {
		if filterSegment.selectedSegmentIndex == 3 {	// release year selected
			rangeSliderLowerLabel.text = String(Int(sender.lowerValue.rounded(.toNearestOrAwayFromZero)))
			rangeSliderUpperLabel.text = String(Int(sender.upperValue.rounded(.toNearestOrAwayFromZero)))
		} else {	//length selected
			rangeSliderLowerLabel.text = TimeInterval(sender.lowerValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
			rangeSliderUpperLabel.text = TimeInterval(sender.upperValue).rounded(.toNearestOrAwayFromZero).stringFromTimeInterval()
		}
	}
	
}
