//
//  YYTTagCell.swift
//  YouTag
//
//  Created by Youstanzr on 3/12/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class YYTTagCell: UICollectionViewCell {

	let titleLabel: UILabel = {
		let label = UILabel()
		label.textAlignment = .center
		label.numberOfLines = 1
		label.lineBreakMode = .byTruncatingMiddle
		return label
	}()
	let textField: SearchTextField = {
		let txtfld = SearchTextField()
		txtfld.addPadding(padding: .equalSpacing(7.5))
		txtfld.tintColor = .white
		txtfld.backgroundColor = UIColor.clear
		txtfld.autocorrectionType = .no
		txtfld.returnKeyType = .done
		return txtfld
	}()
    let suggestionTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
	let imageView: UIImageView = {
		let imgView = UIImageView()
		imgView.contentMode = .scaleAspectFit
		return imgView
	}()
	var image: UIImage? {
		didSet {
			refreshImageView()
		}
	}
	var desc = String()
	
	fileprivate var titleLabelDefaultLeadingAnchor: NSLayoutConstraint?
	fileprivate var titleLabelWithImageLeadingAnchor: NSLayoutConstraint?

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.layer.cornerRadius = self.frame.height / 2.0
		self.layer.borderWidth = 2.0
        self.clipsToBounds = false
        self.contentView.clipsToBounds = false
		
		// calculates the insets of the maximum square touching the corners of the cell
		let imageViewInset = 0.5 * self.frame.height / (2.0 * sqrt(2.0)) + 2
		imageView.isHidden = true
		self.addSubview(imageView)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -imageViewInset).isActive = true
		imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: imageViewInset).isActive = true
		imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: imageViewInset).isActive = true
		imageView.widthAnchor.constraint(equalTo: self.imageView.heightAnchor).isActive = true

		self.contentView.addSubview(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -2.5).isActive = true
		titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 6).isActive = true  // Because the font is shifted upward
		titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -2.5).isActive = true
		titleLabelDefaultLeadingAnchor = titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 2.5)
		titleLabelWithImageLeadingAnchor = titleLabel.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor)
		titleLabelDefaultLeadingAnchor?.isActive = true
		titleLabelWithImageLeadingAnchor?.isActive = false

		textField.isHidden = true
		self.contentView.addSubview(textField)
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -2.5).isActive = true
		textField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 2.5).isActive = true
		textField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -2.5).isActive = true
		textField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 6).isActive = true  // Because the font is shifted upward
        textField.addTarget(self, action: #selector(YYTTagCell.textChanged), for: .editingChanged) // adding text change selector
	}
    
    // This function will fire whenever the user is typing out a new tag to add to a song
    @objc func textChanged(txtField: UITextField) {
        let tagList = LibraryManager.getAll(.tags)
        for i in 0 ..< tagList.count {
            print("Tag: \(tagList[i])")
        }
        if (txtField.text!.length == 0) {
            suggestionTableView.isHidden = true
        } else {
            suggestionTableView.isHidden = false
        }
        (txtField as! SearchTextField).filterStrings(tagList as! [String])
        UIApplication.shared.keyWindow!.bringSubviewToFront(suggestionTableView)
    }
    
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func refreshImageView() {
		imageView.isHidden = false
		imageView.image = image
		titleLabelDefaultLeadingAnchor?.isActive = false
		titleLabelWithImageLeadingAnchor?.isActive = true
		self.layoutIfNeeded()
	}
	
	func switchMode(enableEditing: Bool) {
		textField.text = ""
		if enableEditing {
			titleLabel.isHidden = true
			textField.isHidden = false
			textField.becomeFirstResponder()
		} else {
			titleLabel.isHidden = false
			textField.isHidden = true
		}
	}
	
}
