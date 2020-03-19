//
//  YTTagCell.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/12/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class YTTagCell: UICollectionViewCell {
	let titleLabel: UILabel = {
		let label = UILabel()
		label.textAlignment = .center
		label.numberOfLines = 1
		label.lineBreakMode = .byTruncatingMiddle
		return label
	}()
	let textField: UITextField = {
		let txtfld = UITextField()
		txtfld.addPadding(padding: .equalSpacing(5))
		txtfld.backgroundColor = UIColor.clear
		txtfld.returnKeyType = .done
		txtfld.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		return txtfld
	}()
	

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.layer.cornerRadius = self.frame.height/2.0
		self.layer.borderWidth = 2.0
		self.contentView.addSubview(titleLabel)
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
		self.titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -2.5).isActive = true
		self.titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 2.5).isActive = true
		self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -2.5).isActive = true
		self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 2.5).isActive = true
		self.contentView.addSubview(textField)
		textField.isHidden = true
		self.textField.translatesAutoresizingMaskIntoConstraints = false
		self.textField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -2.5).isActive = true
		self.textField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 2.5).isActive = true
		self.textField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -2.5).isActive = true
		self.textField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 2.5).isActive = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func switchMode(enableEditing: Bool) {
		self.textField.text = ""
		if enableEditing {
			self.titleLabel.isHidden = true
			self.textField.isHidden = false
			textField.becomeFirstResponder()
		} else {
			self.titleLabel.isHidden = false
			self.textField.isHidden = true
		}
	}
}
