//
//  PlaylistLibraryView.swift
//  YouTag
//
//  Created by Youstanzr on 2/29/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

protocol PlaylistLibraryViewDelegate: AnyObject {
    func didSelectSong(song: Song)
}

class PlaylistLibraryView: LibraryTableView {

    weak var PLDelegate: PlaylistLibraryViewDelegate?

    private var longPressValues: (indexPath: IndexPath?, cellSnapShot: UIView?) = (nil, nil)
    
    // MARK: - Initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        addLongPressGesture()
    }

    // MARK: - Log Press Gesture Event
    private func addLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        longPress.minimumPressDuration = 0.3
        self.addGestureRecognizer(longPress)
    }

    // MARK: - UITableView Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(0, PlaylistManager.shared.currentPlaylist.count - 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath) as? LibraryCell else {
            return UITableViewCell()
        }
        
        guard !PlaylistManager.shared.currentPlaylist.isEmpty else { return UITableViewCell() }

        let adjustedIndex = (PlaylistManager.shared.currentPlaylist.count - 2 - indexPath.row) % PlaylistManager.shared.currentPlaylist.count
        let song = PlaylistManager.shared.currentPlaylist[adjustedIndex]
        
        cell.refreshCell(with: song, showTags: true)
        return cell
    }

    // MARK: - UITableView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let adjustedIndex = (PlaylistManager.shared.currentPlaylist.count - 2 - indexPath.row) % PlaylistManager.shared.currentPlaylist.count
        let song = PlaylistManager.shared.currentPlaylist[adjustedIndex]

        print("Selected cell number \(indexPath.row) -> \(song.title)")
        
        // Rotate playlist so selected song plays last
        PlaylistManager.shared.currentPlaylist.insert(PlaylistManager.shared.currentPlaylist.last!, at: 0)
        PlaylistManager.shared.currentPlaylist.removeLast()
        PlaylistManager.shared.currentPlaylist.removeAll { $0.id == song.id }

        PlaylistManager.shared.currentPlaylist.append(song)

        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadData()
        
        PLDelegate?.didSelectSong(song: song)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let adjustedIndex = (PlaylistManager.shared.currentPlaylist.count - 2 - indexPath.row) % PlaylistManager.shared.currentPlaylist.count
            PlaylistManager.shared.currentPlaylist.remove(at: adjustedIndex)
            tableView.reloadData()
        }
    }

    // MARK: - Long Press Gesture for Rearranging Cells
    @objc private func longPressGestureRecognized(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let locationInView = gestureRecognizer.location(in: self)
        guard let indexPath = self.indexPathForRow(at: locationInView) else { return }
        
        switch gestureRecognizer.state {
        case .began:
            guard let cell = self.cellForRow(at: indexPath) as? LibraryCell else { return }
            longPressValues.indexPath = indexPath
            longPressValues.cellSnapShot = cell.snapshotOfView()
            longPressValues.cellSnapShot?.center = cell.center
            longPressValues.cellSnapShot?.alpha = 0.0
            self.addSubview(longPressValues.cellSnapShot!)
            
            UIView.animate(withDuration: 0.25) {
                self.longPressValues.cellSnapShot?.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                self.longPressValues.cellSnapShot?.alpha = 0.98
                cell.alpha = 0.0
            } completion: { finished in
                if finished {
                    cell.isHidden = true
                }
            }
            
        case .changed:
            guard let cellSnapShot = longPressValues.cellSnapShot else { return }
            cellSnapShot.center.y = locationInView.y
            
            if indexPath != longPressValues.indexPath {
                PlaylistManager.shared.currentPlaylist.swapAt(indexPath.row, longPressValues.indexPath!.row)
                self.moveRow(at: longPressValues.indexPath!, to: indexPath)
                longPressValues.indexPath = indexPath
            }
            
        default:
            guard let originalIndexPath = longPressValues.indexPath,
                  let cell = self.cellForRow(at: originalIndexPath) as? LibraryCell else { return }
            
            UIView.animate(withDuration: 0.25) {
                self.longPressValues.cellSnapShot?.center = cell.center
                self.longPressValues.cellSnapShot?.transform = .identity
                self.longPressValues.cellSnapShot?.alpha = 0.0
                cell.alpha = 1.0
            } completion: { finished in
                if finished {
                    self.longPressValues.cellSnapShot?.removeFromSuperview()
                    self.longPressValues = (nil, nil)
                    cell.isHidden = false
                }
            }
        }
    }
}
