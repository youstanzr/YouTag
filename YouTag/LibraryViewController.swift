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
import StoreKit

class LibraryViewController: UIViewController, UIDocumentPickerDelegate, UISearchBarDelegate {

    private let quotaBadge = UIView()
    private let quotaLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = GraphicColors.cloudWhite
        lbl.font = UIFont(name: "DINCondensed-Bold", size: 16)
        lbl.textAlignment = .left
        lbl.text = "0 / 25"
        return lbl
    }()

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
        config.titlePadding = -10.0
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
        NotificationCenter.default.addObserver(
            forName: .libraryTableDidRefresh,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateQuotaLabel()
        }
        NotificationCenter.default.addObserver(
                    forName: .subscriptionEntitlementDidChange,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    guard let self else { return }
                    // Re-read data + refresh UI tied to caps/unlocks
                    self.libraryTableView.refreshTableView()
                    self.allSongs = LibraryManager.shared.libraryArray
                    self.searchBar(self.searchBar, textDidChange: self.searchBar.text ?? "")
                    self.updateQuotaLabel()
                }
        
        // Tap to open paywall (only meaningful on free tier)
        let tap = UITapGestureRecognizer(target: self, action: #selector(quotaBadgeTapped))
        quotaBadge.addGestureRecognizer(tap)
        quotaBadge.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        libraryTableView.refreshTableView()
        allSongs = LibraryManager.shared.libraryArray
        searchBar(searchBar, textDidChange: searchBar.text ?? "")
        updateQuotaLabel()
        // Ensure entitlement is current when returning to this screen
        Task { await SubscriptionManager.shared.updateEntitlementStatus() }
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

        // Quota badge (visible, professional look)
        quotaBadge.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.8)
        quotaBadge.layer.shadowColor = UIColor.black.cgColor
        quotaBadge.layer.shadowOpacity = 0.25
        quotaBadge.layer.shadowOffset = CGSize(width: 0, height: -2)
        quotaBadge.layer.shadowRadius = 4
        quotaBadge.addBorder(side: .top, color: GraphicColors.darkGray, width: 1.0)

        view.addSubview(quotaBadge)
        quotaBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quotaBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            quotaBadge.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            quotaBadge.bottomAnchor.constraint(equalTo: dismissButton.topAnchor),
            quotaBadge.heightAnchor.constraint(equalToConstant: 26)
        ])

        quotaBadge.addSubview(quotaLabel)
        quotaLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quotaLabel.centerXAnchor.constraint(equalTo: quotaBadge.centerXAnchor),
            quotaLabel.heightAnchor.constraint(equalTo: quotaBadge.heightAnchor),
            quotaLabel.centerYAnchor.constraint(equalTo: quotaBadge.centerYAnchor)
        ])

        libraryTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            libraryTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            libraryTableView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -5),
            libraryTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            libraryTableView.bottomAnchor.constraint(equalTo: quotaBadge.topAnchor)
        ])
    }

    // MARK: - Add Button Action
    @objc func addButtonAction(sender: UIButton!) {
        print("Add Button tapped")
        let songCount = LibraryManager.shared.libraryArray.count
        if !SubscriptionManager.shared.canImport(currentCount: songCount) {
            presentPaywall()
            return
        }

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
        // Upfront quota gate: block entire selection if it would exceed the cap
        let mgr = SubscriptionManager.shared
        let currentCount = LibraryManager.shared.libraryArray.count
        if !mgr.isPremium {
            let remaining = mgr.remainingQuota(currentCount: currentCount) ?? 0
            if urls.count > remaining {
                let overBy = urls.count - remaining
                let cap = Limits.freeCap
                let msg = remaining > 0
                    ? "You can import only \(remaining) more song\(remaining == 1 ? "" : "s") on the free plan (cap: \(cap)). Your selection exceeds the limit by \(overBy)."
                    : "You've reached the free plan limit of \(cap) songs. Upgrade to import more."

                let alert = UIAlertController(title: "Import Limit Reached", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                    self?.presentPaywall()
                }))
                present(alert, animated: true)
                return
            }
        }

        // Proceed with import (selection fits within allowance or user is premium)
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
                    self.updateQuotaLabel()
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
        libraryTableView.refreshTableView()
        allSongs = LibraryManager.shared.libraryArray
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.lowercased()
        if text.isEmpty {
            libraryTableView.refreshTableView()
            allSongs = LibraryManager.shared.libraryArray
        } else {
            LibraryManager.shared.libraryArray = allSongs.filter { song in
                song.title.lowercased().contains(text)
                || song.artists.contains(where: { $0.lowercased().contains(text) })
                || (song.album?.lowercased().contains(text) ?? false)
                || song.tags.contains(where: { $0.lowercased().contains(text) })
            }
            libraryTableView.reloadData()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    private func updateQuotaLabel() {
        let count = LibraryManager.shared.libraryArray.count
        let mgr = SubscriptionManager.shared
        let sep = quotaBadge.subviews.first
        if mgr.isPremium {
            quotaLabel.textColor = GraphicColors.obsidianBlack
            quotaLabel.text = "\(count) / ∞"
            quotaBadge.backgroundColor = GraphicColors.orange
            sep?.backgroundColor = GraphicColors.orange.withAlphaComponent(0.9)
        } else {
            let cap = Limits.freeCap
            quotaLabel.text = "\(count) / \(cap)"
            if count > cap {
                // Over limit → reddish background tint to indicate restriction
                quotaBadge.backgroundColor = GraphicColors.red.withAlphaComponent(0.85)
                sep?.backgroundColor = GraphicColors.red.withAlphaComponent(0.9)
            } else {
                quotaBadge.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.8)
                sep?.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.6)
            }
            quotaLabel.textColor = GraphicColors.cloudWhite
        }
    }

    private func presentPaywall() {
        PaywallViewController.present(from: self)
    }
    
    @objc private func quotaBadgeTapped() {
        presentPaywall()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .libraryTableDidRefresh, object: nil)
        NotificationCenter.default.removeObserver(self, name: .subscriptionEntitlementDidChange, object: nil)
    }

}
