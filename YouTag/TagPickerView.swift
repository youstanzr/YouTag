//
//  TagPickerView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/15/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

protocol TagPickerViewDelegate: class {
	func processAddedTags(addedTagsList: NSMutableArray)
}

class TagPickerView: UIView {
	weak var delegate: TagPickerViewDelegate?
	
	var tagView: YTTagView!
	let contentView: UIView = {
		let v = UIView()
		v.backgroundColor = .clear
		return v
	}()
	let segmentControl: UISegmentedControl = {
		let s = UISegmentedControl(items: ["Tags","Artist","Length"])
		s.selectedSegmentIndex = 0
		s.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "DINCondensed-Bold", size: 20)!], for: .normal)
		s.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)
		if #available(iOS 13.0, *) {
			s.selectedSegmentTintColor = UIColor.orange.withAlphaComponent(0.8)
			s.layer.maskedCorners = .init()
		} else {
			s.layer.cornerRadius = 0
		}
		return s
	}()
	let pickerView: UIView = {
		let v = UIView()
		v.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)
		return v
	}()
	let closeButton = UIButton()
	let addButton: UIButton = {
		let button = UIButton()
		button.backgroundColor = UIColor(red:0.000, green:0.802, blue:0.041, alpha:1.00)
		button.titleLabel?.textColor = .white
		button.titleLabel?.font = .boldSystemFont(ofSize: 32)
		button.setTitle("+", for: .normal)
		button.contentVerticalAlignment = .top
		button.titleEdgeInsets = UIEdgeInsets(top: -3.5, left: 0.0, bottom: 0.0, right: 0.0)
		return button
	}()

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

		contentView.addSubview(segmentControl)
		segmentControl.translatesAutoresizingMaskIntoConstraints = false
		segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
		segmentControl.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
		segmentControl.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15).isActive = true

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
		pickerView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor).isActive = true
		pickerView.bottomAnchor.constraint(equalTo: addButton.topAnchor).isActive = true
		
		tagView = YTTagView(frame: .zero, tagsList: LibraryManager.getAllTags(), isAddable: false, isMultiSelection: true)
		pickerView.addSubview(tagView)
		tagView.translatesAutoresizingMaskIntoConstraints = false
		tagView.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor, constant: 5).isActive = true
		tagView.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor, constant: -5).isActive = true
		tagView.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 5).isActive = true
		tagView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: -5).isActive = true
	}
	
	func show(withAnimation isAnimated: Bool) {
		print("Show tag picker view")
		if isAnimated {
			
		} else {
			
		}
		tagView.tagsList = LibraryManager.getAllTags()
		tagView.reloadData()
		self.isHidden = false
	}
	
	@objc func close() {
		print("Close button pressed")
		self.isHidden = true
	}
	
	@objc func add() {
		print("Add button pressed")
		if self.tagView.selectedTagList.count > 0 {
			delegate?.processAddedTags(addedTagsList: self.tagView.selectedTagList)
			self.tagView.deselectAllItems()
		}
		self.isHidden = true
	}
}
