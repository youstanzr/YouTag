//
//  SongDetailViewController.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

// This is the view that shows up whenever you add a new song from the web and want to edit its details before adding to your library
class SongDetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var song: Song!
    var tagsView: YYTTagView!
    
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
        txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
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
        // Thumbnail
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            thumbnailImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0 / 3.0)
        ])

        // Title Text Field
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 15),
            titleTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            titleTextField.heightAnchor.constraint(equalToConstant: 34)
        ])

        // Artists Tags View
        artistsTagsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artistsTagsView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 10),
            artistsTagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            artistsTagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            artistsTagsView.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Album Text Field
        albumTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumTextField.topAnchor.constraint(equalTo: artistsTagsView.bottomAnchor, constant: 10),
            albumTextField.leadingAnchor.constraint(equalTo: artistsTagsView.leadingAnchor),
            albumTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.65, constant: -2.5),
            albumTextField.heightAnchor.constraint(equalToConstant: 34)
        ])

        // Release Year Text Field
        releaseYrTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            releaseYrTextField.topAnchor.constraint(equalTo: albumTextField.topAnchor),
            releaseYrTextField.leadingAnchor.constraint(equalTo: albumTextField.trailingAnchor, constant: 5),
            releaseYrTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.35, constant: -2.5),
            releaseYrTextField.heightAnchor.constraint(equalToConstant: 34)
        ])

        // Lyrics Text View
        lyricsTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lyricsTextView.topAnchor.constraint(equalTo: albumTextField.bottomAnchor, constant: 10),
            lyricsTextView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            lyricsTextView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            lyricsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        // Tags View
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagsView.topAnchor.constraint(equalTo: lyricsTextView.bottomAnchor, constant: 10),
            tagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor),
            tagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor),
            tagsView.bottomAnchor.constraint(equalTo: songSizeLabel.topAnchor, constant: -10),
            tagsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])

        // Song Size Label
        songSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            songSizeLabel.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -5),
            songSizeLabel.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            songSizeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
        ])

        // Filename Label
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filenameLabel.topAnchor.constraint(equalTo: songSizeLabel.topAnchor),
            filenameLabel.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            filenameLabel.trailingAnchor.constraint(equalTo: songSizeLabel.leadingAnchor),
        ])

        // Dismiss Button
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dismissButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.09)
        ])
    }
    @objc func dismissView() {
        if !releaseYrTextField.text!.isNumeric && !releaseYrTextField.text!.isEmpty {
            showAlert(message: "Please input correct release year")
        } else if titleTextField.text!.isEmpty {
            showAlert(message: "Please input song title")
        } else {
            updateSong()
            LibraryManager.shared.updateSongDetails(song: song)
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
        if let image = thumbnailImageView.image, image != UIImage(named: "placeholder") {
            if let fileURL = LocalFilesManager.saveImage(image, withName: song.id) {
                // Store only the filename for thumbnailPath
                song.thumbnailPath = fileURL.lastPathComponent
            }
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            thumbnailImageView.image = image
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
            self.view.frame.origin.y -= getMoveableDistance(keyboarHeight: keyboardFrame.height)
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
}
