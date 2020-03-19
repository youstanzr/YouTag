//
//  YTTagView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/12/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

protocol YTTagViewDelegate: class {
	func tagsListChanged(newTagsList: NSMutableArray)
}

class YTTagView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
	weak var ytdelegate: YTTagViewDelegate?
	var isAddable: Bool!
	var tagsList: NSMutableArray!
	var selectedTagList: NSMutableArray!
	private var isEditing: Bool!
	
	init(frame: CGRect, tagsList: NSMutableArray, isAddable: Bool, isMultiSelection: Bool) {
		super.init(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
		self.register(YTTagCell.self, forCellWithReuseIdentifier: "TagCell")
		self.delegate = self
		self.dataSource = self
		self.layer.cornerRadius = 5
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.lightGray.cgColor
		self.backgroundColor = UIColor.clear
		self.allowsMultipleSelection = isMultiSelection
		self.isAddable = isAddable
		self.isEditing = false
		self.tagsList = tagsList
		self.selectedTagList = NSMutableArray()
		let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.addGestureRecognizer(tap)
		let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
		lpgr.minimumPressDuration = 0.5
		lpgr.delegate = self
		self.addGestureRecognizer(lpgr)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func addTags(tagList: NSMutableArray!) {
		self.tagsList.addObjects(from: tagList as! [Any])
		ytdelegate?.tagsListChanged(newTagsList: self.tagsList)
		self.reloadData()
	}
	
	func removeTag(at index: Int) {
		if isAddable {
			self.tagsList.removeObject(at: index-1)
		} else {
			self.tagsList.removeObject(at: index)
		}
		ytdelegate?.tagsListChanged(newTagsList: self.tagsList)
		self.reloadData()
	}

	func deselectAllItems() {
		guard let selectedItems = indexPathsForSelectedItems else { return }
		for indexPath in selectedItems { collectionView(self, didDeselectItemAt: indexPath) }
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets (top: 5, left: 5, bottom: 5, right: 5)
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
			if !isAddable || index.row != 0 {
				let tagCell = self.cellForItem(at: index) as! YTTagCell
				let tagTitle = tagCell.titleLabel.text ?? ""
				let actionSheet = UIAlertController(title: "Are you sure to delete '\(tagTitle)'?", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
				actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
				actionSheet.addAction(UIAlertAction(title: "Delete", style: .default, handler:{ (UIAlertAction) in
					print("User requested delete for \(tagTitle)")
					self.removeTag(at: index.row)
				}))
				let currentController = self.getCurrentViewController()
				currentController?.present(actionSheet, animated: true, completion: nil)
			}
		}
	}

	// MARK: Collection View Data Source
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return isAddable ? tagsList.count+1:tagsList.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let tagCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! YTTagCell
		tagCell.textField.delegate = self
		if isAddable && indexPath.row == 0 {
			tagCell.backgroundColor = UIColor(red:0.000, green:0.802, blue:0.041, alpha:1.00)
			tagCell.layer.borderColor = UIColor(red:0.000, green:0.6, blue:0.041, alpha:1.00).cgColor
			tagCell.titleLabel.textColor = .white
			tagCell.textField.textColor = .white
			tagCell.titleLabel.text = "+"
			tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 24)
		} else {
			tagCell.backgroundColor = .white
			tagCell.titleLabel.textColor = .darkGray
			tagCell.textField.textColor = .darkGray
			tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
			tagCell.layer.borderColor = UIColor(red: 0.984, green: 0.588, blue: 0.188, alpha: 1.0).cgColor
			if isAddable {
				tagCell.titleLabel.text = tagsList.object(at: indexPath.row-1) as? String
			} else {
				tagCell.titleLabel.text = tagsList.object(at: indexPath.row) as? String
			}
		}
		return tagCell
	}
	
	func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						sizeForItemAt indexPath: IndexPath) -> CGSize {
		if isAddable && indexPath.row == 0 {
			let cellSize = isEditing ? CGSize(width: 90, height: 32):CGSize(width: 30, height: 32)
			isEditing = false
			return cellSize
		}
		var titleWidth: CGFloat
		if isAddable {
			titleWidth = (tagsList.object(at: indexPath.row-1) as! String).estimateSizeWidth(font: UIFont.systemFont(ofSize: 17), padding: 20)
		} else {
			titleWidth = (tagsList.object(at: indexPath.row) as! String).estimateSizeWidth(font: UIFont.systemFont(ofSize: 17), padding: 20)
		}
		titleWidth = titleWidth > collectionView.frame.width*0.475 ? collectionView.frame.width*0.475:titleWidth
		return CGSize(width: titleWidth, height: 32)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! YTTagCell
		if isAddable && indexPath.row == 0 {
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
			let cell = collectionView.cellForItem(at: indexPath) as! YTTagCell
			cell.backgroundColor = .gray
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
		(textField.superview?.superview as! YTTagCell).switchMode(enableEditing: false)
		self.performBatchUpdates(nil, completion: nil)
	}

}
