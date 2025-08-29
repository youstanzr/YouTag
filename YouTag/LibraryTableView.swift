//
//  LibraryTableView.swift
//  YouTag
//
//  Created by Youstanzr on 2/27/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

class LibraryTableView: UITableView, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UIDocumentPickerDelegate {
    private var pendingRelinkIndexPath: IndexPath?
    
    public var allowsPlayContextMenu: Bool = false  // Play context when long press
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.register(LibraryCell.self, forCellReuseIdentifier: "LibraryCell")
        self.separatorStyle = .none
        self.delegate = self
        self.dataSource = self
        self.prefetchDataSource = self
    }
    
    func refreshTableView() {
        LibraryManager.shared.refreshLibraryArray()
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LibraryManager.shared.libraryArray.count
    }
    
    // Called a few rows ahead of display
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let reversed = Array(LibraryManager.shared.libraryArray.reversed())
        for ip in indexPaths {
            let song = reversed[ip.row]
            guard let filename = song.thumbnailPath else { continue }
            if LibraryCell.thumbnailCache.object(forKey: filename as NSString) == nil {
                // Trigger a background load into the cache
                let fileURL = LocalFilesManager.getImageFileURL(for: filename)
                DispatchQueue.global(qos: .background).async {
                    if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
                        LibraryCell.thumbnailCache.setObject(img, forKey: filename as NSString)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath) as? LibraryCell else {
            return UITableViewCell()
        }
        
        let reversedSongs = Array(LibraryManager.shared.libraryArray.reversed())
        let song = reversedSongs[indexPath.row]
        
        cell.refreshCell(with: song, showTags: true)

        // Mark broken links in light red
        if let url = LibraryManager.shared.urlForSong(song),
           (try? url.checkResourceIsReachable()) == true {
            cell.backgroundColor = .clear
        } else {
            cell.backgroundColor = GraphicColors.red.withAlphaComponent(0.2)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reversedSongs = Array(LibraryManager.shared.libraryArray.reversed())
        let selectedSong = reversedSongs[indexPath.row]
        
        // Check if playable
        if let url = LibraryManager.shared.urlForSong(selectedSong),
           (try? url.checkResourceIsReachable()) == true {
            // Proceed to detail view
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            guard let songDetailVC = storyboard.instantiateViewController(withIdentifier: "SongDetailViewController") as? SongDetailViewController else { return }
            songDetailVC.song = selectedSong
            songDetailVC.modalPresentationStyle = .fullScreen
            songDetailVC.modalTransitionStyle = .coverVertical
            UIApplication.getCurrentViewController()?.present(songDetailVC, animated: true, completion: nil)
        } else {
            // Prompt user to relink
            pendingRelinkIndexPath = indexPath
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.audio, .movie],
                asCopy: false
            )
            picker.delegate = self
            picker.allowsMultipleSelection = false
            picker.modalPresentationStyle = .formSheet
            UIApplication.getCurrentViewController()?.present(picker, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reversedSongs = Array(LibraryManager.shared.libraryArray.reversed())
            let songToDelete = reversedSongs[indexPath.row]
            
            // Show a confirmation alert before deletion
            let alert = UIAlertController(title: "Delete Song", message: "Are you sure you want to delete '\(songToDelete.title)'?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                // Remove associated thumbnail if present
                LocalFilesManager.deleteImage(named: songToDelete.thumbnailPath)
                // Delete song record and its links
                LibraryManager.shared.deleteSongFromLibrary(songID: songToDelete.id)
                self.refreshTableView()
            }))
            UIApplication.getCurrentViewController()?.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UIContextMenu

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard allowsPlayContextMenu else { return nil }
        let reversedSongs = Array(LibraryManager.shared.libraryArray.reversed())
        let song = reversedSongs[indexPath.row]
        guard let url = LibraryManager.shared.urlForSong(song),
              (try? url.checkResourceIsReachable()) == true else { return nil }
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { _ in
            let play = UIAction(title: "Play", image: UIImage(systemName: "play.fill")) { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // Rotate playlist so selected song plays last (mirror PlaylistLibraryView.didSelectRowAt)
                if !PlaylistManager.shared.currentPlaylist.isEmpty {
                    if let last = PlaylistManager.shared.currentPlaylist.last {
                        PlaylistManager.shared.currentPlaylist.insert(last, at: 0)
                        PlaylistManager.shared.currentPlaylist.removeLast()
                    }
                    PlaylistManager.shared.currentPlaylist.removeAll { $0.id == song.id }
                }
                PlaylistManager.shared.currentPlaylist.append(song)
                // Refresh playlist UI and play
                PlaylistManager.shared.playlistLibraryView.refreshTableView()
                PlaylistManager.shared.didSelectSong(song: song)
            }
            return UIMenu(title: "", children: [play])
        }
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard allowsPlayContextMenu,
            let ip = configuration.identifier as? NSIndexPath,
            let cell = tableView.cellForRow(at: ip as IndexPath)
        else { return nil }
        let params = UIPreviewParameters()
        params.backgroundColor = UIColor.clear
        return UITargetedPreview(view: cell.contentView, parameters: params)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard allowsPlayContextMenu,
            let ip = configuration.identifier as? NSIndexPath,
            let cell = tableView.cellForRow(at: ip as IndexPath)
        else { return nil }
        let params = UIPreviewParameters()
        params.backgroundColor = UIColor.clear
        return UITargetedPreview(view: cell.contentView, parameters: params)
    }
        
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Ensure single selection and a pending relink index
        guard let indexPath = pendingRelinkIndexPath,
              let fileURL = urls.first else { return }

        // Start security-scoped access
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource for \(fileURL)")
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        // Trigger iCloud download if needed
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
        } catch {
            print("Failed to start iCloud download for \(fileURL): \(error)")
        }

        // Prepare song and destination
        let songList = Array(LibraryManager.shared.libraryArray.reversed())
        var song = songList[indexPath.row]
        let ext = fileURL.pathExtension
        let destName = "\(song.id).\(ext)"

        // Coordinate reading and copy the file
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordError: NSError?
        var copiedURL: URL?
        coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordError) { readURL in
            copiedURL = LocalFilesManager.copySongFile(from: readURL, named: destName)
        }
        if let error = coordError {
            print("File coordination error for relink: \(error)")
        }

        // Update song record if copy succeeded
        if let localURL = copiedURL {
            song.filePath = localURL.lastPathComponent
            LibraryManager.shared.updateSongDetails(song: song)
        } else {
            print("❌ Failed to copy selected file for relink")
        }

        // Refresh UI and clear pending index
        refreshTableView()
        pendingRelinkIndexPath = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
}
