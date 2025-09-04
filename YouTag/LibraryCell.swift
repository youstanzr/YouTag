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
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.layer.borderWidth = 0.5
        imgView.layer.borderColor = GraphicColors.darkGray.cgColor
        imgView.layer.cornerRadius = 5
        imgView.layer.masksToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()

    private let titleLabel: MarqueeLabel = {
        let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
        lbl.trailingBuffer = 40.0
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 17)
        lbl.textAlignment = .left
        lbl.textColor = GraphicColors.cloudWhite
        return lbl
    }()

    /// Combined artist • album • releaseYear
    private let subLabel: MarqueeLabel = {
        let lbl = MarqueeLabel(frame: .zero, rate: 45.0, fadeLength: 10.0)
        lbl.trailingBuffer = 40.0
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 13)
        lbl.textColor = GraphicColors.medGray
        lbl.textAlignment = .left
        return lbl
    }()

    private let durationLabel: UILabel = {
        let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
        lbl.trailingBuffer = 40.0
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 14)
          lbl.textColor = GraphicColors.medGray
        lbl.textAlignment = .right
        return lbl
    }()

    private let tagView: YYTTagView = {
        let style = TagViewStyle(
            isAddEnabled: false,
            isMultiSelection: false,
            isDeleteEnabled: false,
            showsBorder: false,
            cellFont: UIFont(name: "Damascus", size: 14)!,
            overflow: .truncateTail,
            horizontalPadding: 0,
            verticalPadding: 0,
            cellHorizontalPadding: 15,
            cellBorderWidth: 1,
            cellTextColor: GraphicColors.medGray
        )
        let view = YYTTagView(
            frame: .zero,
            tagsList: [],
            suggestionDataSource: nil,
            style: style
        )
        view.isUserInteractionEnabled = false
        return view
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
    func refreshCell(with song: Song, showTags: Bool) {
        titleLabel.text = song.title.isEmpty ? "Unknown Title" : song.title
        // Build subLabel as "Artist • Album • Year"
        let parts = [
            song.album ?? "",
            song.releaseYear ?? "",
            song.artists.joined(separator: ", "),
        ].filter { !$0.isEmpty }
        subLabel.text = parts.joined(separator: "  •  ")

        durationLabel.text = song.duration

        // Restart marquee and set direction based on text
        titleLabel.restartLabel()
        titleLabel.type = titleLabel.text!.isRTL ? .continuousReverse : .continuous

        // Restart marquee on subLabel
        subLabel.restartLabel()
        subLabel.type = subLabel.text!.isRTL ? .continuousReverse : .continuous

        // Update tag view
        if showTags && !song.tags.isEmpty {
            tagView.isHidden = false
            tagView.tagsList = song.tags
            tagView.collectionView.reloadData()
        } else {
            tagView.isHidden = true
        }

        loadThumbnail(from: song.thumbnailPath)
        
        // Add custom separator
        let separator = UIView(frame: CGRect(x: 0, y: self.contentView.frame.height - 0.5, width: self.contentView.frame.width, height: 0.5))
        separator.backgroundColor = GraphicColors.darkGray
        separator.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        self.contentView.addSubview(separator)
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
        self.backgroundColor = .clear

        // Highlight color when pressed
        let highlightView = UIView()
        highlightView.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.2)
        self.selectedBackgroundView = highlightView
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(tagView)
        
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        tagView.translatesAutoresizingMaskIntoConstraints = false
        
//        titleLabel.backgroundColor = .blue
//        subLabel.backgroundColor = .green
//        durationLabel.backgroundColor = .red
//        tagView.backgroundColor = .cyan

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 70),
            thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0 / 3.0),

            // Title row
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 1.5),
            titleLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.38, constant: -3),

            // SubLabel row
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1.5),
            subLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.27),

            // Duration stays on right, centered vertically across cell
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),

            // TagView row
            tagView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            tagView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            tagView.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 3),
            tagView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -1.5),
        ])
    }

}
