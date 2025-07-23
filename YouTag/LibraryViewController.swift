//
//  LibraryViewController.swift
//  YouTag
//
//  Created by Youstanzr on 8/13/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import AVFoundation

class LibraryViewController: UIViewController, UIDocumentPickerDelegate, UISearchBarDelegate {

    private var allSongs: [Song] = []
    private let searchBar = UISearchBar()

    let addButton: UIButton = {
        let btn = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.orange
        config.title = "+"
        config.attributedTitle = AttributedString("+", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 42)]))
        config.baseForegroundColor = .white
        config.titleAlignment = .center
        config.titlePadding = -10.0 // Adjust padding
        config.background.cornerRadius = 0
        btn.configuration = config
        btn.addBorder(side: .left, color: .darkGray, width: 1.0)
        return btn
    }()
    let dismissButton: UIButton = {
        let btn = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.orange
        config.title = "✔︎"
        config.attributedTitle = AttributedString("✔︎", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 30)]))
        config.baseForegroundColor = .white
        config.titleAlignment = .center
        config.background.cornerRadius = 0
        btn.configuration = config
        btn.addBorder(side: .right, color: .darkGray, width: 1.0)
        return btn
    }()
    let libraryTableView = LibraryTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GraphicColors.backgroundWhite
        
        setupUI()
        
        // Capture full list and configure search bar
        allSongs = LibraryManager.shared.libraryArray
        // Configure plain UISearchBar
        searchBar.placeholder = "Search..."
        searchBar.delegate = self
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.returnKeyType = .search
        searchBar.sizeToFit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.libraryTableView.refreshTableView()
    }

    // MARK: - Setup UI
    func setupUI() {
        // Add Search Bar
        self.view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        // Library Table View
        libraryTableView.backgroundColor = .clear
        self.view.addSubview(libraryTableView)
        
        // Add Button
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        self.view.addSubview(addButton)

        // Dismiss Button
        dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        self.view.addSubview(dismissButton)

        libraryTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            libraryTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            libraryTableView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -5),
            libraryTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            libraryTableView.bottomAnchor.constraint(equalTo: addButton.topAnchor)
        ])
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            addButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5),
            addButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.09),
            addButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            dismissButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5),
            dismissButton.topAnchor.constraint(equalTo: addButton.topAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    // MARK: - Add Button Action
    @objc func addButtonAction(sender: UIButton!) {
        print("Add Button tapped")

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .movie], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.modalPresentationStyle = .formSheet

        self.present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - Document Picker Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            // Initialize a Song model with defaults
            var song = Song.from(url: url)

            // Compute destination name and copy into sandbox
            let ext = url.pathExtension
            let destName = "\(song.id).\(ext)"
            
            Task {
                // 1) Copy the file into Documents/Songs
                guard let localURL = LocalFilesManager.copySongFile(from: url, named: destName) else {
                    // If copy fails, alert and skip
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Import Error",
                            message: "Could not copy \(url.lastPathComponent) into the app folder.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        UIApplication.getCurrentViewController()?.present(alert, animated: true)
                    }
                    return
                }
                // Store the relative path
                song.filePath = localURL.lastPathComponent

                // 2) Extract duration from the copied file
                song.duration = await LocalFilesManager.extractDurationForSong(fileURL: localURL)

                // 3) Extract metadata from the copied file
                let metadata = await LocalFilesManager.extractSongMetadata(from: localURL)
                song = LibraryManager.shared.enrichSong(fromMetadata: metadata, for: song)

                // 4) Insert into DB and refresh UI
                LibraryManager.shared.addSongToLibrary(song: song)
                DispatchQueue.main.async {
                    self.libraryTableView.refreshTableView()
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }

    // MARK: - Dismiss Action
    @objc func dismiss(sender: UIButton) {
        print("Dismiss button tapped")
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        // Restore full song list
        LibraryManager.shared.libraryArray = allSongs
        libraryTableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.lowercased()
        if text.isEmpty {
            LibraryManager.shared.libraryArray = allSongs
        } else {
            LibraryManager.shared.libraryArray = allSongs.filter { song in
                song.title.lowercased().contains(text)
                || song.artists.contains(where: { $0.lowercased().contains(text) })
                || (song.album?.lowercased().contains(text) ?? false)
                || song.tags.contains(where: { $0.lowercased().contains(text) })
            }
        }
        libraryTableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}
