//
//  YYTFilterTagView.swift
//  YouTag
//
//  Created by Youstanzr on 3/26/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class YYTFilterTagView: YYTTagView {
    
    private var tupleTags: [[String]] = [[]]

    init(frame: CGRect, tagsList: [[String]], isDeleteEnabled: Bool) {
        let extractedTags = tagsList.compactMap { $0.count > 1 ? $0[1] : nil } // Avoid out-of-bounds error
        super.init(frame: frame, tagsList: extractedTags, isAddEnabled: false, isMultiSelection: false, isDeleteEnabled: isDeleteEnabled, suggestionDataSource: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTags(with newTags: [[String]]) {
        self.tupleTags = newTags
        self.tagsList = newTags.compactMap { $0[1] }
        self.reloadData() // Refresh UI
    }
    
    override func removeTag(at index: Int) {
        let actualIndex = isAddEnabled ? index - 1 : index
        selectedTagList.removeAll { $0 == tagsList[actualIndex] }
        tagsList.remove(at: actualIndex)
        tupleTags.remove(at: actualIndex)
        yytdelegate?.tagsListChanged(newTagsList: tupleTags)
        reloadData()
    }

    override func removeAllTags() {
        tagsList.removeAll()
        tupleTags.removeAll()
        selectedTagList.removeAll()
        yytdelegate?.tagsListChanged(newTagsList: tupleTags)
        reloadData()
    }

    
    func getImageForType(_ type: String) -> UIImage {
        switch type {
            case "tags":
                return UIImage(named: "tag")!
            case "artist":
                return UIImage(named: "artist")!
            case "album":
                return UIImage(named: "album")!
            case "releaseYearRange":
                return UIImage(named: "calendar")!
            case "releaseYear":
                return UIImage(named: "calendar")!
            case "duration":
                return UIImage(named: "duration")!
            default:
                return UIImage()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tagCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! YYTTagCell
        tagCell.textField.delegate = self
        if isAddEnabled && indexPath.row == 0 {
            tagCell.backgroundColor = GraphicColors.green
            tagCell.layer.borderColor = GraphicColors.darkGreen.cgColor
            tagCell.textField.textColor = .white
            tagCell.textField.placeholder = addTagPlaceHolder
            tagCell.titleLabel.textColor = .white
            tagCell.titleLabel.text = "+"
            tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 24)
        } else {
            tagCell.image = UIImage(named: "list")
            tagCell.backgroundColor = .clear
            tagCell.titleLabel.textColor = .darkGray
            tagCell.textField.textColor = .darkGray
            tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
            tagCell.layer.borderColor = GraphicColors.orange.cgColor
            
            let index = isAddEnabled ? indexPath.row - 1 : indexPath.row
            let tuple = tupleTags[index]
            tagCell.titleLabel.text = tuple[1]
            tagCell.desc = tuple[0]
            tagCell.image = getImageForType(tagCell.desc)
        }
        return tagCell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isAddEnabled && indexPath.row == 0 {
            let cellSize = isEditingEnabled ? CGSize(width: 90, height: 32):CGSize(width: 30, height: 32)
            isEditingEnabled = false
            return cellSize
        }
        let index = isAddEnabled ? indexPath.row - 1 : indexPath.row
        let title = tagsList[index]
        var titleWidth = title.estimateSizeWidth(font: UIFont(name: "DINCondensed-Bold", size: 16)!, padding: 5.0)
        titleWidth = min(titleWidth, collectionView.frame.width * 0.475)
        return CGSize(width: titleWidth + 34, height: 32)
        
    }

}
