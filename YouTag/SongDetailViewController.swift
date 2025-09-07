//
//  SongDetailViewController.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit
import QuickLook

class SongDetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, QLPreviewControllerDataSource {
    
    var song: Song!
    var tagsView: YYTTagView!
    private var previewURL: URL?
    // Track if artwork was changed by user
    private var artworkChanged = false
    
    // Thumbnail size constraints (portrait vs landscape)
    private var portraitThumbHeight: NSLayoutConstraint!
    private var landscapeThumbHeight: NSLayoutConstraint!
    // Extra constraints to stabilize transitions
    private var portraitThumbMinHeight: NSLayoutConstraint!
    private var landscapeThumbMinHeight: NSLayoutConstraint!
    private var landscapeThumbCenterYConstraint: NSLayoutConstraint!

    // Thumbnail position constraints (portrait vs landscape)
    private var portraitThumbPosConstraints: [NSLayoutConstraint] = []
    private var landscapeThumbPosConstraints: [NSLayoutConstraint] = []

    // Form layout constraints (portrait vs landscape)
    private var portraitFormConstraints: [NSLayoutConstraint] = []
    private var landscapeFormConstraints: [NSLayoutConstraint] = []
    
    let dismissButton: UIButton = {
        let btn = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.obsidianBlack
        config.title = "✔︎"
        config.attributedTitle = AttributedString("✔︎", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 30)]))
        config.baseForegroundColor = GraphicColors.orange
        config.titleAlignment = .center
        config.contentInsets = NSDirectionalEdgeInsets(top: 2.5, leading: 0.0, bottom: 0.0, trailing: 0.0)
        btn.configuration = config
        btn.addBorder(side: .top, color: GraphicColors.darkGray, width: 1.0)
        return btn
    }()
    let thumbnailImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.layer.cornerRadius = 5.0
        imgView.layer.borderWidth = 1.0
        imgView.layer.borderColor = GraphicColors.lightGray.cgColor
        imgView.layer.masksToBounds = true
        imgView.isUserInteractionEnabled = true
        return imgView
    }()
    let titleTextField: UITextField = {
        let txtField = UITextField()
        txtField.backgroundColor = .clear
        txtField.textColor = GraphicColors.cloudWhite
        txtField.textAlignment = .left
        txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
        txtField.autocorrectionType = .no
        txtField.placeholder = "Title"
        txtField.addPadding(padding: .equalSpacing(5))
        txtField.returnKeyType = .done
        txtField.layer.cornerRadius = 5
        txtField.layer.borderWidth = 1.0
        txtField.layer.borderColor = GraphicColors.darkGray.cgColor
        return txtField
    }()
    var artistsTagsView: YYTTagView!
    let albumTextField: SearchTextField = {
        let txtField = SearchTextField()
        txtField.textColor = GraphicColors.cloudWhite
        txtField.theme.bgColor = .white
        txtField.theme.separatorColor = .darkGray
        txtField.theme.borderColor = GraphicColors.orange
        txtField.maxNumberOfResults = 5
        txtField.backgroundColor = .clear
        txtField.textAlignment = .left
        txtField.font = UIFont(name: "DINCondensed-Bold", size: 16)
        txtField.autocorrectionType = .no
        txtField.attributedPlaceholder = NSAttributedString(
            string: "Album",
            attributes: [
                .foregroundColor: GraphicColors.medGray,
                .font: UIFont.init(name: "DINCondensed-Bold", size: 16)!
            ])
        txtField.addPadding(padding: .equalSpacing(5))
        txtField.returnKeyType = .done
        txtField.layer.cornerRadius = 5
        txtField.layer.borderWidth = 1.0
        txtField.layer.borderColor = GraphicColors.darkGray.cgColor
        txtField.theme.font = UIFont(name: "DINCondensed-Bold", size: 16)!
        txtField.highlightAttributes = [NSAttributedString.Key.backgroundColor: GraphicColors.yellow.withAlphaComponent(0.3), NSAttributedString.Key.font:txtField.theme.font]
        
        return txtField
    }()
    let releaseYrTextField: UITextField = {
        let txtField = UITextField()
        txtField.textColor = GraphicColors.cloudWhite
        txtField.backgroundColor = .clear
        txtField.textAlignment = .left
        txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
        txtField.autocorrectionType = .no
        txtField.attributedPlaceholder = NSAttributedString(
            string: "Release Year",
            attributes: [
                .foregroundColor: GraphicColors.medGray,
                .font: UIFont.init(name: "DINCondensed-Bold", size: 16)!
            ])
        txtField.addPadding(padding: .equalSpacing(5))
        txtField.keyboardType = .numberPad
        txtField.returnKeyType = .done
        txtField.layer.cornerRadius = 5
        txtField.layer.borderWidth = 1.0
        txtField.layer.borderColor = GraphicColors.darkGray.cgColor
        return txtField
    }()
    let lyricsTextView: UITextView = {
        let txtView = UITextView()
        txtView.textColor = GraphicColors.medGray
        txtView.backgroundColor = .clear
        txtView.textAlignment = .left
        txtView.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
        txtView.autocorrectionType = .no
        txtView.text = "Lyrics"
        txtView.layer.cornerRadius = 5
        txtView.layer.borderWidth = 1.0
        txtView.layer.borderColor = GraphicColors.darkGray.cgColor
        return txtView
    }()
    let imagePicker = UIImagePickerController()
    let songSizeLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = GraphicColors.darkGray
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
        lbl.textAlignment = .right
        return lbl
    }()
    
    let filenameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = GraphicColors.darkGray
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
        lbl.textAlignment = .left
        return lbl
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        populateFields()
    }
    
    private func setupUI() {
        view.backgroundColor = GraphicColors.obsidianBlack
        setupObservers()
        
        // Thumbnail
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        thumbnailImageView.addGestureRecognizer(imageTap)
        // Long press to remove artwork
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(thumbnailLongPressed(_:)))
        longPress.minimumPressDuration = 0.5
        thumbnailImageView.addGestureRecognizer(longPress)
        view.addSubview(thumbnailImageView)
        
        // Title
        titleTextField.delegate = self
        view.addSubview(titleTextField)
        
        // Artists Tags View
        let artistsStyle = TagViewStyle(
            isAddEnabled: true,
            isMultiSelection: false,
            isDeleteEnabled: true,
            showsBorder: true,
            cellFont: UIFont(name: "DINCondensed-Bold", size: 16)!,
            overflow: .scrollable,
            verticalPadding: 5
        )
        artistsTagsView = YYTTagView(
            frame: .zero,
            tagsList: [],
            suggestionDataSource: LibraryManager.shared.getAllDistinctValues(for: "artists"),
            style: artistsStyle
        )
        artistsTagsView.addTagPlaceHolder = "Artist"
        view.addSubview(artistsTagsView)
        
        // Album
        albumTextField.delegate = self
        albumTextField.itemSelectionHandler = {item, itemPosition in
            self.albumTextField.text = item[itemPosition].title
            self.albumTextField.resignFirstResponder()
        }
        albumTextField.filterStrings(LibraryManager.shared.getAllDistinctValues(for: "album"))
        view.addSubview(albumTextField)
        
        // Release Year
        releaseYrTextField.delegate = self
        view.addSubview(releaseYrTextField)
        
        // Lyrics
        lyricsTextView.delegate = self
        view.addSubview(lyricsTextView)
        
        // Tags View
        let tagsStyle = TagViewStyle(
            isAddEnabled: true,
            isMultiSelection: false,
            isDeleteEnabled: true,
            showsBorder: true,
            cellFont: UIFont(name: "DINCondensed-Bold", size: 16)!,
            overflow: .scrollable,
            verticalPadding: 5
        )
        tagsView = YYTTagView(
            frame: .zero,
            tagsList: song.tags,
            suggestionDataSource: LibraryManager.shared.getAllDistinctValues(for: "tags"),
            style: tagsStyle
        )
        tagsView.addTagPlaceHolder = "Tag"
        view.addSubview(tagsView)
        
        // Dismiss Button
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        view.addSubview(dismissButton)
        
        // Song Size Label
        if let fileURL = LibraryManager.shared.urlForSong(song) {
            songSizeLabel.text = "\(LocalFilesManager.getLocalFileSize(fileURL: fileURL))"
        } else {
            songSizeLabel.text = "?? MB"
        }
        view.addSubview(songSizeLabel)
        
        // Filename Label
        if let fileURL = LibraryManager.shared.urlForSong(song) {
            filenameLabel.text = "\(fileURL.lastPathComponent)"
        } else {
            filenameLabel.text = "Unknown"
        }
        // Make filename label tappable to open the file (Quick Look)
        filenameLabel.isUserInteractionEnabled = true
        let filenameTap = UITapGestureRecognizer(target: self, action: #selector(previewFile))
        filenameLabel.addGestureRecognizer(filenameTap)
        if let currentText = filenameLabel.text {
            filenameLabel.attributedText = NSAttributedString(
                string: currentText,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ]
            )
        }
        view.addSubview(filenameLabel)
        
        setupConstraints()
    }
    
    private func populateFields() {
        titleTextField.text = song.title
        albumTextField.text = song.album
        releaseYrTextField.text = song.releaseYear
        let lyrics = song.lyrics ?? ""
        lyricsTextView.text = lyrics.isEmpty ? "Lyrics" : lyrics
        lyricsTextView.textColor = lyrics.isEmpty ? GraphicColors.medGray : GraphicColors.cloudWhite
        
        // Populate artists tags
        artistsTagsView.tagsList = song.artists
        artistsTagsView.collectionView.reloadData()
        
        // Populate other tags
        tagsView.tagsList = song.tags
        tagsView.collectionView.reloadData()
        
        thumbnailImageView.image = LibraryManager.shared.fetchThumbnail(for: song)
        ?? UIImage(named: "placeholder")
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide
        // Thumbnail
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        // Thumbnail position variants
        portraitThumbPosConstraints = [
            thumbnailImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
            thumbnailImageView.centerXAnchor.constraint(equalTo: safe.centerXAnchor)
        ]
        landscapeThumbCenterYConstraint = thumbnailImageView.centerYAnchor.constraint(equalTo: safe.centerYAnchor)
        landscapeThumbCenterYConstraint.priority = UILayoutPriority(750)
        landscapeThumbPosConstraints = [
            thumbnailImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            landscapeThumbCenterYConstraint
        ]
        
        // Use soft caps (≤, priority 999) so both can be active during transitions
        portraitThumbHeight = thumbnailImageView.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6)
        portraitThumbHeight.priority = UILayoutPriority(999)
        landscapeThumbHeight = thumbnailImageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.6)
        landscapeThumbHeight.priority = UILayoutPriority(999)
        // Sensible minimums to avoid collapsing
        portraitThumbMinHeight = thumbnailImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        landscapeThumbMinHeight = thumbnailImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140)
        NSLayoutConstraint.activate([portraitThumbHeight, landscapeThumbHeight, portraitThumbMinHeight, landscapeThumbMinHeight])

        NSLayoutConstraint.activate([
            // keep aspect ratio after setting height
            thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0 / 3.0)
        ])
        if traitCollection.verticalSizeClass == .compact {
            NSLayoutConstraint.activate(landscapeThumbPosConstraints)
        } else {
            NSLayoutConstraint.activate(portraitThumbPosConstraints)
        }
        
        // Between field padding constant
        let pad: CGFloat = 10

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        artistsTagsView.translatesAutoresizingMaskIntoConstraints = false
        albumTextField.translatesAutoresizingMaskIntoConstraints = false
        releaseYrTextField.translatesAutoresizingMaskIntoConstraints = false
        lyricsTextView.translatesAutoresizingMaskIntoConstraints = false
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        songSizeLabel.translatesAutoresizingMaskIntoConstraints = false

        // PORTRAIT layout
        portraitFormConstraints = [
            titleTextField.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: pad * 1.5),
            titleTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleTextField.widthAnchor.constraint(equalTo: safe.widthAnchor, multiplier: 0.8),
            titleTextField.heightAnchor.constraint(equalToConstant: 34),

            artistsTagsView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: pad),
            artistsTagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            artistsTagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            artistsTagsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            albumTextField.topAnchor.constraint(equalTo: artistsTagsView.bottomAnchor, constant: pad),
            albumTextField.leadingAnchor.constraint(equalTo: artistsTagsView.leadingAnchor),
            albumTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.65, constant: -pad * 0.25),
            albumTextField.heightAnchor.constraint(equalToConstant: 34),

            releaseYrTextField.topAnchor.constraint(equalTo: albumTextField.topAnchor),
            releaseYrTextField.leadingAnchor.constraint(equalTo: albumTextField.trailingAnchor, constant: pad * 0.5),
            releaseYrTextField.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            releaseYrTextField.heightAnchor.constraint(equalToConstant: 34),

            lyricsTextView.topAnchor.constraint(equalTo: albumTextField.bottomAnchor, constant: pad),
            lyricsTextView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            lyricsTextView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            lyricsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            tagsView.topAnchor.constraint(equalTo: lyricsTextView.bottomAnchor, constant: pad),
            tagsView.bottomAnchor.constraint(equalTo: filenameLabel.topAnchor, constant: -pad),
            tagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            tagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            tagsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            songSizeLabel.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -pad * 0.75),
            songSizeLabel.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            songSizeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            songSizeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            songSizeLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 40),
            
            filenameLabel.topAnchor.constraint(equalTo: songSizeLabel.topAnchor),
            filenameLabel.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            filenameLabel.trailingAnchor.constraint(equalTo: songSizeLabel.leadingAnchor),
            filenameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            filenameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 40),
            filenameLabel.bottomAnchor.constraint(lessThanOrEqualTo: dismissButton.topAnchor, constant: -pad * 0.75),
        ]

        // LANDSCAPE layout: single right-column stack (like portrait), thumbnail on left
        landscapeFormConstraints = [
            // Left: Thumbnail capped size
            thumbnailImageView.widthAnchor.constraint(lessThanOrEqualTo: safe.widthAnchor, multiplier: 0.5),

            // Right column (stack all fields vertically like portrait)
            titleTextField.topAnchor.constraint(equalTo: safe.topAnchor, constant: pad * 2),
            titleTextField.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: pad * 2),
            titleTextField.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 34),

            artistsTagsView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: pad),
            artistsTagsView.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            artistsTagsView.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            artistsTagsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            albumTextField.topAnchor.constraint(equalTo: artistsTagsView.bottomAnchor, constant: pad),
            albumTextField.leadingAnchor.constraint(equalTo: artistsTagsView.leadingAnchor),
            albumTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.65, constant: -pad * 0.25),
            albumTextField.heightAnchor.constraint(equalToConstant: 34),

            releaseYrTextField.topAnchor.constraint(equalTo: albumTextField.topAnchor),
            releaseYrTextField.leadingAnchor.constraint(equalTo: albumTextField.trailingAnchor, constant: pad * 0.5),
            releaseYrTextField.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            releaseYrTextField.heightAnchor.constraint(equalToConstant: 34),
            
            lyricsTextView.topAnchor.constraint(equalTo: albumTextField.bottomAnchor, constant: pad),
            lyricsTextView.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            lyricsTextView.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            lyricsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            tagsView.topAnchor.constraint(equalTo: lyricsTextView.bottomAnchor, constant: pad),
            tagsView.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            tagsView.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            tagsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            tagsView.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -pad * 2),
            
            filenameLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: pad),
            filenameLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor, constant: pad),
            filenameLabel.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -pad),
            filenameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),

            songSizeLabel.topAnchor.constraint(equalTo: filenameLabel.bottomAnchor, constant: pad),
            songSizeLabel.leadingAnchor.constraint(equalTo: filenameLabel.leadingAnchor),
            songSizeLabel.trailingAnchor.constraint(equalTo: filenameLabel.trailingAnchor),
            songSizeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            songSizeLabel.bottomAnchor.constraint(lessThanOrEqualTo: dismissButton.topAnchor, constant: -pad * 0.75),
        ]

        // Proportional growth: distribute extra vertical space as Lyrics : Artists : Tags = 10 : 3 : 6
        // Keep existing minimum heights; these are soft ratio constraints to guide growth only.
        // Artists ≤ 0.3 × Lyrics, Tags ≤ 0.6 × Lyrics, and Tags == 2 × Artists
        let artistsVsLyrics = artistsTagsView.heightAnchor.constraint(lessThanOrEqualTo: lyricsTextView.heightAnchor, multiplier: 0.3)
        artistsVsLyrics.priority = UILayoutPriority(900)
        let tagsVsLyrics = tagsView.heightAnchor.constraint(lessThanOrEqualTo: lyricsTextView.heightAnchor, multiplier: 0.6)
        tagsVsLyrics.priority = UILayoutPriority(900)
        let tagsVsArtists = tagsView.heightAnchor.constraint(equalTo: artistsTagsView.heightAnchor, multiplier: 2.0)
        tagsVsArtists.priority = UILayoutPriority(900)
        NSLayoutConstraint.activate([artistsVsLyrics, tagsVsLyrics, tagsVsArtists])

        // Make all three willing to grow: lower vertical hugging so they expand to satisfy the ratios
        lyricsTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        artistsTagsView.setContentHuggingPriority(.defaultLow, for: .vertical)
        tagsView.setContentHuggingPriority(.defaultLow, for: .vertical)

        // Prefer shrinking lyrics and tags before fields (keep existing) and include artists as well
        lyricsTextView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        artistsTagsView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        tagsView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        // Activate the appropriate set now
        applyLayoutForCurrentTraits()

        // Dismiss Button
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dismissButton.applyStandardBottomBarHeight(70)
    }
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        UIView.animate(withDuration: 0.2) {
            self.applyLayoutForCurrentTraits()
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.applyLayoutForCurrentTraits()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // Helper to update constraints and alignments for current trait environment
    private func applyLayoutForCurrentTraits() {
        // Decide orientation by size class (works on iPhone/iPad, incl. split view)
        let isLandscape = traitCollection.verticalSizeClass == .compact

        // 1) Toggle the right-hand form stacks
        NSLayoutConstraint.deactivate(portraitFormConstraints)
        NSLayoutConstraint.deactivate(landscapeFormConstraints)
        NSLayoutConstraint.activate(isLandscape ? landscapeFormConstraints : portraitFormConstraints)

        // 2) Toggle thumbnail position constraints
        NSLayoutConstraint.deactivate(portraitThumbPosConstraints)
        NSLayoutConstraint.deactivate(landscapeThumbPosConstraints)
        NSLayoutConstraint.activate(isLandscape ? landscapeThumbPosConstraints : portraitThumbPosConstraints)

        // 3) Update label alignments to match layout
        filenameLabel.textAlignment = isLandscape ? .center : .left
        songSizeLabel.textAlignment = isLandscape ? .center : .right
    }

    @objc func dismissView() {
        releaseYrTextField.text = releaseYrTextField.text?.latinDigits
        if !releaseYrTextField.text!.isNumeric && !releaseYrTextField.text!.isEmpty {
            showAlert(message: "Please input correct release year")
        } else if titleTextField.text!.isEmpty {
            showAlert(message: "Please input song title")
        } else {
            updateSong()
            LibraryManager.shared.updateSongDetails(song: song)
            if let name = song.thumbnailPath, !name.isEmpty {
                LibraryCell.thumbnailCache.removeObject(forKey: name as NSString)
            }
            dismiss(animated: true, completion: nil)
        }
    }

    private func updateSong() {
        song.title = titleTextField.text ?? ""
        song.artists = artistsTagsView.tagsList
        song.album = albumTextField.text
        song.releaseYear = releaseYrTextField.text
        song.lyrics = lyricsTextView.textColor == GraphicColors.medGray ? "" : lyricsTextView.text
        song.tags = tagsView.tagsList

        // Handle artwork only if changed by user (picked new one or deleted)
        if artworkChanged {
            // If user set a custom image (not placeholder), (re)save it
            if let image = thumbnailImageView.image, image != UIImage(named: "placeholder") {
                // Save (overwrite) under a stable name based on song id
                if let fileURL = LocalFilesManager.saveImage(image, withName: song.id) {
                    let oldName = song.thumbnailPath
                    // Store only the filename for thumbnailPath
                    song.thumbnailPath = fileURL.lastPathComponent
                    // Invalidate cache so LibraryCell reloads from disk
                    if let oldName = oldName, !oldName.isEmpty {
                        LibraryCell.thumbnailCache.removeObject(forKey: oldName as NSString)
                    }
                    LibraryCell.thumbnailCache.removeObject(forKey: fileURL.lastPathComponent as NSString)
                }
            } else {
                // User cleared artwork; ensure path is nil and invalidate cache
                if let oldName = song.thumbnailPath, !oldName.isEmpty {
                    LibraryCell.thumbnailCache.removeObject(forKey: oldName as NSString)
                }
                song.thumbnailPath = nil
            }
            artworkChanged = false
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func imageTapped() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    @objc private func thumbnailLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        // Only offer delete if there is a custom image
        let hasCustomArtwork = (thumbnailImageView.image != UIImage(named: "placeholder")) || (song.thumbnailPath != nil)
        guard hasCustomArtwork else { return }

        let alert = UIAlertController(title: "Delete Artwork", message: "Delete the current artwork for this song?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            // Delete stored thumbnail file if present
            if let name = self.song.thumbnailPath, !name.isEmpty {
                LocalFilesManager.deleteImage(named: name)
            }
            // Reset model and UI
            let oldName = self.song.thumbnailPath
            self.song.thumbnailPath = nil
            self.thumbnailImageView.image = UIImage(named: "placeholder")
            self.artworkChanged = true
            // Invalidate any cached image for this song
            if let oldName = oldName, !oldName.isEmpty {
                LibraryCell.thumbnailCache.removeObject(forKey: oldName as NSString)
            }
            // Persist change
            LibraryManager.shared.updateSongDetails(song: self.song)
        }))

        // iPad presentation safety
        if let pop = alert.popoverPresentationController {
            pop.sourceView = thumbnailImageView
            pop.sourceRect = thumbnailImageView.bounds
        }
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            thumbnailImageView.image = image
            artworkChanged = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text!.capitalized.trim()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == GraphicColors.medGray {
            textView.text = nil
            textView.textColor = GraphicColors.cloudWhite
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.text = textView.text.trim()
        textView.contentOffset = .zero
        if textView.text == "" || textView.text.replacingOccurrences(of: "\n", with: "") == "" {
            textView.text = "Lyrics"
            textView.textColor = GraphicColors.medGray
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= getMoveableDistance(keyboarHeight: keyboardFrame.height + 55)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func getMoveableDistance(keyboarHeight: CGFloat) ->  CGFloat {
        var y:CGFloat = 0.0
        if let activeTF = getSelectedTextField() {
            var tfMaxY = activeTF.frame.maxY
            var containerView = activeTF.superview!
            while containerView.frame.maxY != self.view.frame.maxY {
                let contViewFrm = containerView.convert(activeTF.frame, to: containerView.superview)
                tfMaxY = tfMaxY + contViewFrm.minY
                containerView = containerView.superview!
            }
            let keyboardMinY = self.view.frame.height - keyboarHeight
            if tfMaxY + 10.0 > keyboardMinY {
                y = (tfMaxY - keyboardMinY) + 10.0
            }
        } else if let activeTV = getSelectedTextView() {
            var tvMaxY = activeTV.frame.maxY
            var containerView = activeTV.superview!
            while containerView.frame.maxY != self.view.frame.maxY {
                let contViewFrm = containerView.convert(activeTV.frame, to: containerView.superview)
                tvMaxY = tvMaxY + contViewFrm.minY
                containerView = containerView.superview!
            }
            let keyboardMinY = self.view.frame.height - keyboarHeight
            if tvMaxY + 10.0 > keyboardMinY {
                y = (tvMaxY - keyboardMinY) + 10.0
            }
        }
        return y
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Quick Look preview of the song file
    @objc private func previewFile() {
        guard let url = LibraryManager.shared.urlForSong(song) else { return }
        previewURL = url
        
        DispatchQueue.main.async {
            guard self.presentedViewController == nil else { return }
            let preview = QLPreviewController()
            preview.dataSource = self
            // Add our own Done button (since we’re embedding in a nav controller)
            preview.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissPreview))
            
            let nav = UINavigationController(rootViewController: preview)
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .coverVertical
            nav.navigationBar.tintColor = GraphicColors.orange
            self.present(nav, animated: true)
        }
    }
    
    // QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return previewURL == nil ? 0 : 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewURL! as NSURL
    }
    
    @objc private func dismissPreview() {
        self.dismiss(animated: true)
    }
}
