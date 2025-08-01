//
//  YYTTagView.swift
//  YouTag
//
//  Created by Youstanzr on 3/12/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

/// Configuration style for YYTTagView
struct TagViewStyle {
    enum OverflowBehavior {
        case truncateTail   // single-line, truncates excess tags
        case scrollable     // horizontal scrolling
    }
    var isAddEnabled: Bool = false
    var isMultiSelection: Bool = false
    var isDeleteEnabled: Bool = false
    var showsBorder: Bool = true
    var cellFont: UIFont = UIFont(name: "DINCondensed-Bold", size: 16)!
    var overflow: OverflowBehavior = .truncateTail
    var horizontalPadding: CGFloat = 5
    var verticalPadding: CGFloat = 5
    /// Total horizontal padding (added to text width) per cell
    var cellHorizontalPadding: CGFloat = 32.0/1.5
    /// Width of the border around each tag cell
    var cellBorderWidth: CGFloat = 1.25
    var cellTextColor: UIColor = GraphicColors.cloudWhite
}

protocol YYTTagViewDelegate: AnyObject {
    func tagsListChanged(newTagsList: [[String]])
}

class YYTTagView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    let style: TagViewStyle
    let collectionView: UICollectionView

    weak var yytdelegate: YYTTagViewDelegate?
    var addTagPlaceHolder: String!
    var tagsList: [String] = [] {
        didSet {
            selectedTagList = []
            suggestionsList = suggestionsList?.filter { !tagsList.contains($0) }
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    var suggestionsList: [String]? {
        didSet {
            suggestionsList = suggestionsList?.filter { !tagsList.contains($0) }
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    var selectedTagList: [String] = []
    var isEditingEnabled: Bool = false

    private let fadeCountLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        lbl.textColor = GraphicColors.orange
        lbl.textAlignment = .center
        lbl.backgroundColor = GraphicColors.medGray.withAlphaComponent(0.3)
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()


    init(frame: CGRect, tagsList: [String], suggestionDataSource: [String]? = nil, style: TagViewStyle) {
        let layout = LeftAlignedCollectionViewFlowLayout()
        // Set scroll direction per overflow mode
        if style.overflow == .scrollable {
            layout.scrollDirection = .vertical
        } else {
            layout.scrollDirection = .horizontal
        }
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 7.5
        layout.sectionInset = UIEdgeInsets(
            top: style.verticalPadding,
            left: style.horizontalPadding,
            bottom: style.verticalPadding,
            right: style.horizontalPadding
        )
        self.style = style
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        // Set scrolling and clipping based on overflow mode
        self.collectionView.isScrollEnabled = (style.overflow == .scrollable)
        self.clipsToBounds = true
        self.collectionView.register(YYTTagCell.self, forCellWithReuseIdentifier: "TagCell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.layer.cornerRadius = 5
        self.layer.borderWidth = style.showsBorder ? 1.0 : 0.0
        self.layer.borderColor = GraphicColors.darkGray.cgColor
        self.backgroundColor = UIColor.clear
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.allowsMultipleSelection = style.isMultiSelection
        self.tagsList = tagsList
        self.suggestionsList = suggestionDataSource
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
        if self.style.isDeleteEnabled {
            let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            lpgr.minimumPressDuration = 0.5
            lpgr.delegate = self
            self.addGestureRecognizer(lpgr)
        }
        addSubview(collectionView)
        addSubview(fadeCountLabel)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyFadeMaskIfNeeded()
        // Position and style hidden-count label
        let labelWidth: CGFloat = 30
        var labelHeight: CGFloat = bounds.height - style.verticalPadding * 2
        let xPos = bounds.width - style.horizontalPadding - labelWidth
        var yPos = style.verticalPadding

        let heightRatio = 0.8
        yPos = yPos + labelHeight * (1 - heightRatio)/2
        labelHeight = labelHeight * heightRatio

        fadeCountLabel.frame = CGRect(x: xPos, y: yPos, width: labelWidth, height: labelHeight)
        fadeCountLabel.layer.cornerRadius = labelHeight / 2
        fadeCountLabel.clipsToBounds = true
    }
  
    /// Applies a horizontal fade mask at the right edge when in truncateTail mode, using the collectionView's layer mask property.
    private func applyFadeMaskIfNeeded() {
        guard style.overflow == .truncateTail,
              let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            // No truncate: clear mask
            collectionView.layer.mask = nil
            fadeCountLabel.isHidden = true
            return
        }

        let insets = flowLayout.sectionInset
        let spacing = flowLayout.minimumInteritemSpacing
        // total width of all items + insets
        let totalWidth = tagsList.enumerated().reduce(insets.left + insets.right) { acc, pair in
            let (i, tag) = pair
            let w = tag.estimateSizeWidth(font: style.cellFont, padding: style.cellHorizontalPadding)
            return acc + w + (i > 0 ? spacing : 0)
        }
        // no mask if everything fits
        guard totalWidth > bounds.width else {
            collectionView.layer.mask = nil
            fadeCountLabel.isHidden = true
            return
        }

        // build the gradient mask
        let fadeWidth = 0.125
        let mask = CAGradientLayer()
        // Make sure layout is up-to-date
        collectionView.layoutIfNeeded()
        mask.frame = collectionView.bounds
        mask.startPoint = CGPoint(x: 0, y: 0.5)
        mask.endPoint   = CGPoint(x: 1, y: 0.5)
        let bg = GraphicColors.obsidianBlack.cgColor
        mask.colors = [
            bg,
            bg,
            bg.copy(alpha: 0.0)!,
            bg.copy(alpha: 0.0)!,
        ]
        mask.locations = [
            NSNumber(value: 0.0),
            NSNumber(value: 1.0 - 2.0 * fadeWidth),
            NSNumber(value: 1.0 - fadeWidth),
            NSNumber(value: 1.0)
        ]
        // Use as mask: mask fades the rightmost content, revealing background/highlight
        mask.frame = collectionView.bounds
        collectionView.layer.mask = mask

        // Count tags with ≤50% visibility
        let insetRight = flowLayout.sectionInset.right
        let maxX = bounds.width * (1 - 1.5 * fadeWidth) - insetRight
        var accX = flowLayout.sectionInset.left
        var hiddenCount = 0
        for tag in tagsList {
            let w = tag.estimateSizeWidth(font: style.cellFont, padding: style.cellHorizontalPadding)
            let tagMinX = accX
            let visibleWidth = max(0, min(w, maxX - tagMinX))
            let shouldHide = (visibleWidth / w) <= 0.5
            if shouldHide { hiddenCount += 1 }
            accX += w + flowLayout.minimumInteritemSpacing
        }

        if hiddenCount > 0 {
            fadeCountLabel.text = "+\(hiddenCount)"
            fadeCountLabel.isHidden = false
        } else {
            fadeCountLabel.isHidden = true
        }
        // Ensure the count label renders above the masked content
        bringSubviewToFront(fadeCountLabel)
    }
    
    func removeTag(at index: Int) {
        let actualIndex = style.isAddEnabled ? index - 1 : index
        selectedTagList.removeAll { $0 == tagsList[actualIndex] }
        tagsList.remove(at: actualIndex)
        self.collectionView.reloadData()
    }

    func removeAllTags() {
        tagsList.removeAll()
        selectedTagList.removeAll()
        self.collectionView.reloadData()
    }

    func deselectAllTags() {
        guard let selectedItems = self.collectionView.indexPathsForSelectedItems else { return }
        for indexPath in selectedItems {
            collectionView(self.collectionView, didDeselectItemAt: indexPath)
        }
        self.collectionView.reloadData()
    }

    // MARK: Long Press Gesture Recognizer
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        // If there are no tags to delete, do nothing
        if tagsList.isEmpty { return }
        if gestureReconizer.state != .began { return }
        let p = gestureReconizer.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: p)
        
        //check if the long press was into the collection view or the cells
        if let index = indexPath {
            if !style.isAddEnabled || index.row != 0 {
                let tagCell = self.collectionView.cellForItem(at: index) as! YYTTagCell
                let tagTitle = tagCell.titleLabel.text ?? ""
                let actionSheet = UIAlertController(title: "Are you sure to delete '\(tagTitle)'?", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
                actionSheet.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
                    self.removeTag(at: index.row)
                })

                UIApplication.getCurrentViewController()?.present(actionSheet, animated: true, completion: nil)
            }
        } else {
            let actionSheet = UIAlertController(title: "Are you sure to delete all tags?", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
                print("User requested delete for all tags")
                self.removeAllTags()
            })
            UIApplication.getCurrentViewController()?.present(actionSheet, animated: true, completion: nil)
        }
    }

    // MARK: Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return style.isAddEnabled ? tagsList.count + 1:tagsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tagCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! YYTTagCell
        tagCell.textField.delegate = self
        // Apply consistent cell border width
        tagCell.layer.borderWidth = style.cellBorderWidth

        if style.isAddEnabled && indexPath.row == 0 {
            tagCell.backgroundColor = GraphicColors.green
            tagCell.layer.borderColor = GraphicColors.darkGreen.cgColor
            tagCell.titleLabel.textColor = GraphicColors.cloudWhite
            tagCell.titleLabel.text = "+"
            tagCell.titleLabel.font = style.cellFont
            tagCell.textField.textColor = GraphicColors.cloudWhite
            tagCell.textField.placeholder = addTagPlaceHolder
        } else {
            tagCell.backgroundColor = tagCell.isSelected ? GraphicColors.orange : UIColor.clear
            tagCell.titleLabel.textColor = style.cellTextColor
            tagCell.titleLabel.font = style.cellFont
            tagCell.textField.textColor = style.cellTextColor
            tagCell.layer.borderColor = GraphicColors.orange.cgColor
            let index = style.isAddEnabled ? indexPath.row - 1 : indexPath.row
            tagCell.titleLabel.text = tagsList[index]
        }
        tagCell.textField.font = style.cellFont
        tagCell.textField.theme.font = style.cellFont
        tagCell.textField.highlightAttributes = [NSAttributedString.Key.backgroundColor: GraphicColors.yellow.withAlphaComponent(0.3), NSAttributedString.Key.font:tagCell.textField.theme.font]
        return tagCell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if style.isAddEnabled && indexPath.row == 0 {
            let cellSize = isEditingEnabled ? CGSize(width: collectionView.frame.width * 0.475, height: 32):CGSize(width: 30, height: 32)
            isEditingEnabled = false
            return cellSize
        }
        let index = style.isAddEnabled ? indexPath.row - 1 : indexPath.row
        // Horizontal: text width + horizontal padding
        let textWidth = tagsList[index].estimateSizeWidth(font: style.cellFont, padding: style.cellHorizontalPadding)
        let clampedWidth = min(textWidth, collectionView.frame.width * 0.475)
        if style.overflow == .scrollable {
            return CGSize(width: clampedWidth, height: 32)
        } else {
            return CGSize(width: clampedWidth, height: self.frame.height)
        }
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! YYTTagCell
        if style.isAddEnabled && indexPath.row == 0 {
            print("Add Tag Button tapped")
            isEditingEnabled = true
            cell.switchMode(enableEditing: true)
            cell.textField.filterStrings(self.suggestionsList ?? [])
            collectionView.performBatchUpdates(nil, completion: nil)
        } else if self.collectionView.allowsMultipleSelection {
            cell.backgroundColor = GraphicColors.orange
            selectedTagList.append(cell.titleLabel.text!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.collectionView.allowsMultipleSelection {
            let cell = collectionView.cellForItem(at: indexPath) as? YYTTagCell
            cell?.backgroundColor = .clear
            if let text = cell?.titleLabel.text, let index = selectedTagList.firstIndex(of: text) {
                selectedTagList.remove(at: index)
            }
        }
    }
    
    // MARK: UITextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text?.capitalized.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !text.isEmpty {
            if tagsList.contains(text) {
                let alert = UIAlertController(title: "Duplicate Tag", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        textField.becomeFirstResponder()
                    }
                })
                UIApplication.getCurrentViewController()?.present(alert, animated: true, completion: nil)
                return
            }
            tagsList.append(text)
            self.collectionView.reloadData()
        }
        (textField.superview?.superview as! YYTTagCell).switchMode(enableEditing: false)
        self.collectionView.performBatchUpdates(nil, completion: nil)
    }
}

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)?.map { $0.copy() as! UICollectionViewLayoutAttributes }
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            guard layoutAttribute.representedElementCategory == .cell else {
                return
            }

            if Int(layoutAttribute.frame.origin.y) >= Int(maxY) || layoutAttribute.frame.origin.x == sectionInset.left {
                leftMargin = sectionInset.left
            }
            
            if layoutAttribute.frame.origin.x == sectionInset.left {
                leftMargin = sectionInset.left
            }
            else {
                layoutAttribute.frame.origin.x = leftMargin
            }

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }
        
        return attributes
    }
}
