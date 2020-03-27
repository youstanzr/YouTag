//
//  YYTTagView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/12/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

protocol YYTTagViewDelegate: class {
	func tagsListChanged(newTagsList: NSMutableArray)
}

class YYTTagView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {

	weak var yytdelegate: YYTTagViewDelegate?
	var addTagPlaceHolder: String!
	var isAddEnabled: Bool!
	var isDeleteEnabled: Bool!
	var tagsList: NSMutableArray!
	var selectedTagList: NSMutableArray!
	var isEditing: Bool!
	
	
	init(frame: CGRect, tagsList: NSMutableArray, isAddEnabled: Bool, isMultiSelection: Bool, isDeleteEnabled: Bool) {
		super.init(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
		self.register(YYTTagCell.self, forCellWithReuseIdentifier: "TagCell")
		self.delegate = self
		self.dataSource = self
		self.layer.cornerRadius = 5
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.lightGray.cgColor
		self.backgroundColor = UIColor.clear
		self.allowsMultipleSelection = isMultiSelection
		self.isAddEnabled = isAddEnabled
		self.isDeleteEnabled = isDeleteEnabled
		self.isEditing = false
		self.tagsList = tagsList
		self.selectedTagList = NSMutableArray()
		let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.addGestureRecognizer(tap)
		if isDeleteEnabled {
			let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
			lpgr.minimumPressDuration = 0.5
			lpgr.delegate = self
			self.addGestureRecognizer(lpgr)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
		
	func removeTag(at index: Int) {
		if isAddEnabled {
			self.tagsList.removeObject(at: index-1)
		} else {
			self.tagsList.removeObject(at: index)
		}
		yytdelegate?.tagsListChanged(newTagsList: self.tagsList)
		self.reloadData()
	}

	func removeAllTags() {
		self.tagsList.removeAllObjects()
		yytdelegate?.tagsListChanged(newTagsList: self.tagsList)
		self.reloadData()
	}

	func deselectAllItems() {
		guard let selectedItems = indexPathsForSelectedItems else { return }
		for indexPath in selectedItems { collectionView(self, didDeselectItemAt: indexPath) }
	}

	// MARK: Long Press Gesture Recognizer
	@objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
		if gestureReconizer.state != .began {
			return
		}
		let p = gestureReconizer.location(in: self)
		let indexPath = self.indexPathForItem(at: p)
		
		//check if the long press was into the collection view or the cells
		if let index = indexPath {
			if !isAddEnabled || index.row != 0 {
				let tagCell = self.cellForItem(at: index) as! YYTTagCell
				let tagTitle = tagCell.titleLabel.text ?? ""
				let actionSheet = UIAlertController(title: "Are you sure to delete '\(tagTitle)'?", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
				actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
				actionSheet.addAction(UIAlertAction(title: "Delete", style: .default, handler:{ (UIAlertAction) in
					print("User requested delete for tag: \(tagTitle)")
					self.removeTag(at: index.row)
				}))
				let currentController = self.getCurrentViewController()
				currentController?.present(actionSheet, animated: true, completion: nil)
			}
		} else {
			let actionSheet = UIAlertController(title: "Are you sure to delete all tags?", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
			actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
			actionSheet.addAction(UIAlertAction(title: "Delete", style: .default, handler:{ (UIAlertAction) in
				print("User requested delete for all tags")
				self.removeAllTags()
			}))
			let currentController = self.getCurrentViewController()
			currentController?.present(actionSheet, animated: true, completion: nil)
		}
	}

	// MARK: Collection View
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return isAddEnabled ? tagsList.count+1:tagsList.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let tagCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! YYTTagCell
		tagCell.textField.delegate = self
		if isAddEnabled && indexPath.row == 0 {
			tagCell.backgroundColor = GraphicColors.green
			tagCell.layer.borderColor = GraphicColors.darkGreen.cgColor
			tagCell.titleLabel.textColor = .white
			tagCell.titleLabel.text = "+"
			tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 24)
			tagCell.textField.textColor = .white
			tagCell.textField.placeholder = addTagPlaceHolder
			tagCell.textField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		} else {
			tagCell.backgroundColor = .clear
			tagCell.titleLabel.textColor = .darkGray
			tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
			tagCell.textField.textColor = .darkGray
			tagCell.textField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
			tagCell.layer.borderColor = GraphicColors.orange.cgColor
			let index = isAddEnabled ? indexPath.row - 1 : indexPath.row
			tagCell.titleLabel.text = tagsList.object(at: index) as? String
		}
		return tagCell
	}
	
	func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						sizeForItemAt indexPath: IndexPath) -> CGSize {
		if isAddEnabled && indexPath.row == 0 {
			let cellSize = isEditing ? CGSize(width: 90, height: 32):CGSize(width: 30, height: 32)
			isEditing = false
			return cellSize
		}
		let index = isAddEnabled ? indexPath.row - 1 : indexPath.row
		var titleWidth = (tagsList.object(at: index) as! String).estimateSizeWidth(font: UIFont.init(name: "DINCondensed-Bold", size: 16)!, padding: 32.0 / 1.5)
		titleWidth = titleWidth > collectionView.frame.width * 0.475 ? collectionView.frame.width * 0.475:titleWidth
		return CGSize(width: titleWidth, height: 32)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets (top: 5, left: 5, bottom: 5, right: 5)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! YYTTagCell
		if isAddEnabled && indexPath.row == 0 {
			print("Add Tag Button tapped")
			isEditing = true
			cell.switchMode(enableEditing: true)
			collectionView.performBatchUpdates(nil, completion: nil)
		} else if self.allowsMultipleSelection {
			cell.backgroundColor = .orange
			selectedTagList.add(cell.titleLabel.text!)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		if self.allowsMultipleSelection {
			let cell = collectionView.cellForItem(at: indexPath) as! YYTTagCell
			cell.backgroundColor = .white
			selectedTagList.remove(cell.titleLabel.text!)
		}
	}
	
	// MARK: UITextField Delegate
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField.text != "" {
			if tagsList.contains(textField.text!.capitalized) {
				let alert = UIAlertController(title: "Duplicate Tag", message: nil, preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:{ (UIAlertAction) in
					textField.becomeFirstResponder()
				}))
				self.getCurrentViewController()?.present(alert, animated: true, completion: nil)
				return
			}
			tagsList.add(textField.text!.capitalized)
			self.reloadData()
		}
		(textField.superview?.superview as! YYTTagCell).switchMode(enableEditing: false)
		self.performBatchUpdates(nil, completion: nil)
	}
	
}
