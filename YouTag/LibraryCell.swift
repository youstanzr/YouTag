//
//  LibraryCell.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit
import MarqueeLabel

class LibraryCell : UITableViewCell {
  
    static let thumbnailCache = NSCache<NSString, UIImage>()
    
    // MARK: - UI Elements
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: MarqueeLabel = {
        let label = MarqueeLabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artistLabel: MarqueeLabel = {
        let label = MarqueeLabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cell Configuration
    func refreshCell(with song: Song) {
        titleLabel.text = song.title.isEmpty ? "Unknown Title" : song.title
        let artistsText = song.artists.joined(separator: ", ")
        artistLabel.text = artistsText.isEmpty ? "" : artistsText
        durationLabel.text = song.duration

        // Restart marquee and set direction based on text
        titleLabel.labelize = true
        titleLabel.restartLabel()
        if titleLabel.text != nil && titleLabel.text!.isRTL {
            titleLabel.type = .continuousReverse
        } else {
            titleLabel.type = .continuous
        }

        artistLabel.labelize = true
        artistLabel.restartLabel()
        if artistLabel.text != nil && artistLabel.text!.isRTL {
            artistLabel.type = .continuousReverse
        } else {
            artistLabel.type = .continuous
        }

        loadThumbnail(from: song.thumbnailPath)
    }

    // MARK: - Thumbnail Loading
    private func loadThumbnail(from path: String?) {
        guard let filename = path, !filename.isEmpty else {
            thumbnailImageView.image = UIImage(named: "placeholder")
            return
        }

        // 1) Check cache
        if let img = LibraryCell.thumbnailCache.object(forKey: filename as NSString) {
            thumbnailImageView.image = img
            return
        }

        // 2) Not cached -> fetch from disk async
        let fileURL = LocalFilesManager.getImageFileURL(for: filename)
        DispatchQueue.global(qos: .background).async {
            let img: UIImage?
            if let data = try? Data(contentsOf: fileURL) {
                img = UIImage(data: data)
            } else {
                img = UIImage(named: "placeholder")
            }
            DispatchQueue.main.async {
                // 3) Cache and display
                if let img = img {
                    LibraryCell.thumbnailCache.setObject(img, forKey: filename as NSString)
                }
                self.thumbnailImageView.image = img
            }
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -10),

            artistLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -10),

            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

}
