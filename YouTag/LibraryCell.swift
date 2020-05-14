//
//  LibraryCell.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import MarqueeLabel

class LibraryCell : UITableViewCell {
  
	var songDict = Dictionary<String, Any>()
	let thumbnailImageView: UIImageView = {
		let imgView = UIImageView()
		imgView.layer.cornerRadius = 5.0
		imgView.layer.borderWidth = 1.0
		imgView.layer.borderColor = UIColor.lightGray.cgColor
		imgView.layer.masksToBounds = true
		return imgView
	}()
	let titleLabel: MarqueeLabel = {
		let lbl = MarqueeLabel.init(frame: .zero, duration: 8.0, fadeLength: 10.0)
		lbl.trailingBuffer = 40.0
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22)
		lbl.textAlignment = .left
		return lbl
	}()
	let artistLabel: MarqueeLabel = {
		let lbl = MarqueeLabel.init(frame: .zero, duration: 8.0, fadeLength: 10.0)
		lbl.textColor = GraphicColors.gray
		lbl.trailingBuffer = 40.0
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
		lbl.textAlignment = .left
		return lbl
	}()
	let durationLabel: UILabel = {
		let lbl = UILabel()
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
		lbl.textAlignment = .right
		return lbl
	}()

	
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = .clear
		
        self.contentView.addSubview(thumbnailImageView)
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
		thumbnailImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		thumbnailImageView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -15).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 1.25).isActive = true
		
        self.contentView.addSubview(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10).isActive = true
		titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
		titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 5).isActive = true
		titleLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.55, constant: -5).isActive = true
		
		self.contentView.addSubview(artistLabel)
		artistLabel.translatesAutoresizingMaskIntoConstraints = false
		artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
		artistLabel.widthAnchor.constraint(equalTo: titleLabel.widthAnchor, multiplier: 0.8).isActive = true
		artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
		artistLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor).isActive = true

		self.contentView.addSubview(durationLabel)
		durationLabel.translatesAutoresizingMaskIntoConstraints = false
		durationLabel.leadingAnchor.constraint(equalTo: artistLabel.trailingAnchor).isActive = true
		durationLabel.widthAnchor.constraint(equalTo: titleLabel.widthAnchor, multiplier: 0.2).isActive = true
		durationLabel.topAnchor.constraint(equalTo: artistLabel.topAnchor).isActive = true
		durationLabel.heightAnchor.constraint(equalTo: artistLabel.heightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func refreshCell() {
		self.titleLabel.text = songDict["title"] as? String
		self.artistLabel.text = (songDict["artists"] as? NSArray ?? NSArray())!.componentsJoined(by: ", ")
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songDict["id"] as? String ?? "").jpg"))
		if let imgData = imageData {
			self.thumbnailImageView.image = UIImage(data: imgData)
		} else {
			self.thumbnailImageView.image = UIImage(named: "placeholder")
		}
		self.durationLabel.text = songDict["duration"] as? String
		
		titleLabel.labelize = true
		titleLabel.restartLabel()
		if titleLabel.text!.isRTL {
			titleLabel.type = .continuousReverse
		} else {
			titleLabel.type = .continuous
		}

		artistLabel.labelize = true
		artistLabel.restartLabel()
		if artistLabel.text!.isRTL {
			artistLabel.type = .continuousReverse
		} else {
			titleLabel.type = .continuous
		}
	}
}
