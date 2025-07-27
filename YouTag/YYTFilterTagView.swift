//
//  YYTFilterTagView.swift
//  YouTag
//
//  Created by Youstanzr on 3/26/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class YYTFilterTagView: YYTTagView {
    
    private var tupleTags: [(PlaylistFilters.FilterType, String)] = []

    init(frame: CGRect, tupleTags: [(PlaylistFilters.FilterType, String)], isDeleteEnabled: Bool) {
        self.tupleTags = tupleTags
        let titles = tupleTags.map { $0.1 }
        let style = TagViewStyle(
            isAddEnabled: false,
            isMultiSelection: false,
            isDeleteEnabled: isDeleteEnabled,
            showsBorder: true,
            cellFont: UIFont(name: "DINCondensed-Bold", size: 16)!,
            overflow: .scrollable,
            verticalPadding: 5
        )

        super.init(frame: frame, tagsList: titles, suggestionDataSource: nil, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTags(with newTags: [(PlaylistFilters.FilterType, String)]) {
        self.tupleTags = newTags
        self.tagsList = newTags.map { $0.1 }
        self.collectionView.reloadData() // Refresh UI
    }
    
    override func removeTag(at index: Int) {
        let actualIndex = style.isAddEnabled ? index - 1 : index
        selectedTagList.removeAll { $0 == tagsList[actualIndex] }
        tagsList.remove(at: actualIndex)
        tupleTags.remove(at: actualIndex)
        // Convert tupleTags back into [[String]] for the delegate
        let stringArray = tupleTags.map { [$0.0.rawValue, $0.1] }
        yytdelegate?.tagsListChanged(newTagsList: stringArray)
        self.collectionView.reloadData()
    }

    override func removeAllTags() {
        tagsList.removeAll()
        tupleTags.removeAll()
        selectedTagList.removeAll()
        // Notify delegate with an empty array of string tuples
        yytdelegate?.tagsListChanged(newTagsList: [])
        self.collectionView.reloadData()
    }

    private func getImageForType(_ filter: PlaylistFilters.FilterType) -> UIImage {
        let imageName: String
        switch filter {
        case .tag:
            imageName = "tag"
        case .artist:
            imageName = "artist"
        case .album:
            imageName = "album"
        case .releaseYear, .releaseYearRange:
            imageName = "calendar"
        case .duration:
            imageName = "duration"
        }

        let baseImage = UIImage(named: imageName) ?? UIImage()
        return baseImage.withTintColor(GraphicColors.orange, renderingMode: .alwaysOriginal)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tagCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! YYTTagCell
        tagCell.textField.delegate = self
        if style.isAddEnabled && indexPath.row == 0 {
            tagCell.backgroundColor = GraphicColors.green
            tagCell.layer.borderColor = GraphicColors.darkGreen.cgColor
            tagCell.textField.textColor = GraphicColors.cloudWhite
            tagCell.textField.placeholder = addTagPlaceHolder
            tagCell.titleLabel.textColor = GraphicColors.cloudWhite
            tagCell.titleLabel.text = "+"
            tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 24)
        } else {
            tagCell.backgroundColor = .clear
            tagCell.titleLabel.textColor = GraphicColors.cloudWhite
            tagCell.textField.textColor = GraphicColors.cloudWhite
            tagCell.titleLabel.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
            tagCell.layer.borderColor = GraphicColors.orange.cgColor

            let index = style.isAddEnabled ? indexPath.row - 1 : indexPath.row
            let (filter, title) = tupleTags[index]
            tagCell.titleLabel.text = title
            tagCell.desc = filter.rawValue
            tagCell.image = getImageForType(filter)
        }
        return tagCell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if style.isAddEnabled && indexPath.row == 0 {
            let cellSize = isEditingEnabled ? CGSize(width: 90, height: 32):CGSize(width: 30, height: 32)
            isEditingEnabled = false
            return cellSize
        }
        let index = style.isAddEnabled ? indexPath.row - 1 : indexPath.row
        let title = tagsList[index]
        var titleWidth = title.estimateSizeWidth(font: UIFont(name: "DINCondensed-Bold", size: 16)!, padding: 5.0)
        titleWidth = min(titleWidth, collectionView.frame.width * 0.475)
        return CGSize(width: titleWidth + 34, height: 32)
        
    }

}
