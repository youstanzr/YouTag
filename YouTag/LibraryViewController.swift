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
        config.baseBackgroundColor = GraphicColors.obsidianBlack
        config.title = "+"
        config.attributedTitle = AttributedString("+", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 42)]))
        config.baseForegroundColor = GraphicColors.orange
        config.titleAlignment = .center
        config.titlePadding = -10.0 // Adjust padding
        config.background.cornerRadius = 0
        btn.configuration = config
        btn.addBorder(side: .top, color: GraphicColors.darkGray, width: 1.0)
        btn.addBorder(side: .left, color: GraphicColors.darkGray, width: 0.5)
        return btn
    }()
    let dismissButton: UIButton = {
        let btn = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = GraphicColors.obsidianBlack
        config.title = "✔︎"
        config.attributedTitle = AttributedString("✔︎", attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 30)]))
        config.baseForegroundColor = GraphicColors.orange
        config.titleAlignment = .center
        config.background.cornerRadius = 0
        btn.configuration = config
        btn.addBorder(side: .top, color: GraphicColors.darkGray, width: 1.0)
        btn.addBorder(side: .right, color: GraphicColors.darkGray, width: 0.5)
        return btn
    }()
    let libraryTableView = LibraryTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        libraryTableView.allowsPlayContextMenu = true
        
        // Capture full list and configure search bar
        allSongs = LibraryManager.shared.libraryArray
        // Configure plain UISearchBar
        searchBar.delegate = self
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.returnKeyType = .search
        
        // Keep allSongs in sync with the library whenever the table view refreshes.
        // This ensures search always works with the latest library state, including after deletions.
        NotificationCenter.default.addObserver(
            forName: .libraryTableDidRefresh,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.allSongs = LibraryManager.shared.libraryArray
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.text = ""
        self.libraryTableView.refreshTableView()
    }

    // MARK: - Setup UI
    func setupUI() {
        self.view.backgroundColor = GraphicColors.obsidianBlack

        // Add Search Bar
        searchBar.barTintColor = GraphicColors.obsidianBlack      // Background behind the bar
        searchBar.backgroundColor = GraphicColors.cloudWhite    // Background color
        searchBar.searchTextField.backgroundColor = GraphicColors.obsidianBlack   // Text field bg
        searchBar.searchTextField.textColor = GraphicColors.cloudWhite      // Text color
        searchBar.searchTextField.tintColor = GraphicColors.orange             // Cursor color
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search...",
            attributes: [.foregroundColor: GraphicColors.medGray]
        )
        
        self.view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchBar.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -5),
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
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        addButton.applyStandardBottomBarHeight(70)
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dismissButton.applyStandardBottomBarHeight(70)
    }

    // MARK: - Add Button Action
    @objc func addButtonAction(sender: UIButton!) {
        print("Add Button tapped")
        if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("Documents folder path: \(docDir.path)")
        }

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .movie], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.modalPresentationStyle = .formSheet

        self.present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - Document Picker Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource for \(url)")
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }

            // Trigger iCloud download if needed
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                print("Failed to start iCloud download for \(url): \(error)")
            }

            // Initialize a Song model with defaults
            var song = Song.from(url: url)

            // Compute destination name
            let destName = "\(song.id).\(url.pathExtension)"

            // Coordinate reading and copy the file synchronously
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var coordinationError: NSError?
            var copiedURL: URL?
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
                copiedURL = LocalFilesManager.copySongFile(from: readURL, named: destName)
            }
            if let err = coordinationError {
                print("File coordination error: \(err)")
                continue
            }
            guard let localURL = copiedURL else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Import Error",
                        message: "Could not copy \(url.lastPathComponent) into the app folder.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    UIApplication.getCurrentViewController()?.present(alert, animated: true)
                }
                continue
            }

            // Save path and perform metadata extraction asynchronously
            song.filePath = localURL.lastPathComponent
            Task {
                song.duration = await LocalFilesManager.extractDurationForSong(fileURL: localURL)
                let metadata = await LocalFilesManager.extractSongMetadata(from: localURL)
                song = LibraryManager.shared.enrichSong(fromMetadata: metadata, for: song)
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
        if LibraryManager.shared.libraryArray.isEmpty {
            let alert = UIAlertController(
                title: "No songs found",
                message: "Please add some songs to your library first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
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
