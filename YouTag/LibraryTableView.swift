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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.register(LibraryCell.self, forCellReuseIdentifier: "LibraryCell")
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
        if let filename = song.thumbnailPath,
           LibraryCell.thumbnailCache.object(forKey: filename as NSString) == nil {
          // Trigger a background load into the cache
          let fileURL = LocalFilesManager.getImageFileURL(for: filename)
          DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: fileURL),
               let img = UIImage(data: data) {
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
        
        cell.refreshCell(with: song)
        // Mark broken links in light red
        if let url = LibraryManager.shared.urlForSong(song),
           (try? url.checkResourceIsReachable()) == true {
            cell.backgroundColor = .white
        } else {
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
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
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Ensure we have an indexPath and a single selected file
        guard let indexPath = pendingRelinkIndexPath,
              let fileURL = urls.first else { return }
        
        // Determine the destination filename and copy into Documents/Songs
        let songList = Array(LibraryManager.shared.libraryArray.reversed())
        var song = songList[indexPath.row]
        let ext = fileURL.pathExtension
        let destName = "\(song.id).\(ext)"
        if let localURL = LocalFilesManager.copySongFile(from: fileURL, named: destName) {
            // Update the song's filePath to the sandbox copy
            song.filePath = localURL.lastPathComponent
            // Persist the change to the database
            LibraryManager.shared.updateSongDetails(song: song)
        } else {
            print("❌ Failed to copy selected file for relink")
        }
        
        // Refresh the library display and clear the pending index
        self.refreshTableView()
        pendingRelinkIndexPath = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
}
