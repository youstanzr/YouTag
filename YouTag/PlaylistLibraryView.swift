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
        // Determine tapped indexPath reliably
        let location = gestureRecognizer.location(in: self)
        let clampedLocation = CGPoint(x: location.x, y: min(max(location.y, 0), contentSize.height))
        print("Debug: gesture state = \(gestureRecognizer.state)")
        switch gestureRecognizer.state {
            case .began:
                print("Begin")
                guard let indexPath = self.indexPathForRow(at: location) else { return }
                guard let cell = self.cellForRow(at: indexPath) as? LibraryCell else { return }
                longPressValues.indexPath = indexPath
                longPressValues.cellSnapShot = cell.snapshotOfView()
                longPressValues.cellSnapShot?.center = cell.center
                longPressValues.cellSnapShot?.alpha = 0.0
                self.addSubview(longPressValues.cellSnapShot!)
                
                UIView.animate(withDuration: 0.1) {
                    self.longPressValues.cellSnapShot?.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                    self.longPressValues.cellSnapShot?.alpha = 0.98
                    cell.alpha = 0.0
                } completion: { finished in
                    if finished {
                        cell.isHidden = true
                    }
                }
                
            case .changed:
                print("Debug(.changed): clampedLocation.y = \(clampedLocation.y), contentOffset.y = \(contentOffset.y), bounds.height = \(bounds.height), contentSize.height = \(contentSize.height)")
                print("Changed \(clampedLocation.y)")
                // Auto-scroll when dragging beyond top/bottom
                let scrollSpeed: CGFloat = 10
                var newY: CGFloat = 0
                if location.y < contentOffset.y + bounds.height * 0.3 {
                    newY = max(contentOffset.y - scrollSpeed, 0)       // Scroll up
                    setContentOffset(CGPoint(x: contentOffset.x, y: newY), animated: false)
                } else if location.y > contentOffset.y + bounds.height * 0.7 {
                    let maxOffset = max(contentSize.height - bounds.height, 0)
                    newY = min(contentOffset.y + scrollSpeed, maxOffset)  // Scroll down
                    setContentOffset(CGPoint(x: contentOffset.x, y: newY), animated: false)
                }
                
                guard let cellSnapShot = longPressValues.cellSnapShot else { return }
                cellSnapShot.center.y = clampedLocation.y
                
                let location = gestureRecognizer.location(in: self)
                guard let targetIndexPath = self.indexPathForRow(at: location) else { break }
                
                if targetIndexPath != longPressValues.indexPath {
                    print("Swapping \(targetIndexPath.row) and \(longPressValues.indexPath!.row)")
                    let i1 = (PlaylistManager.shared.currentPlaylist.count - 2 - targetIndexPath.row) % PlaylistManager.shared.currentPlaylist.count
                    let i2 = (PlaylistManager.shared.currentPlaylist.count - 2 - longPressValues.indexPath!.row) % PlaylistManager.shared.currentPlaylist.count
                    PlaylistManager.shared.currentPlaylist.swapAt(i1, i2)
                    self.moveRow(at: longPressValues.indexPath!, to: targetIndexPath)
                    longPressValues.indexPath = targetIndexPath
                }
                
            case .ended, .cancelled, .failed:
                print("Gesture ended")
                guard let snapshot = longPressValues.cellSnapShot,
                      let originalIndexPath = longPressValues.indexPath else {
                    // Nothing to clean up
                    return
                }
                // If the original cell is still visible, animate snapshot back; otherwise just cleanup
                if let cell = self.cellForRow(at: originalIndexPath) as? LibraryCell {
                    UIView.animate(withDuration: 0.1) {
                        snapshot.center = cell.center
                        snapshot.transform = .identity
                        snapshot.alpha = 0.0
                        cell.alpha = 1.0
                    } completion: { _ in
                        snapshot.removeFromSuperview()
                        cell.isHidden = false
                        self.longPressValues = (nil, nil)
                    }
                } else {
                    // Cell went offscreen: simply remove snapshot and restore table
                    snapshot.removeFromSuperview()
                    self.longPressValues = (nil, nil)
                    self.reloadData()
                }
            
            default: break

        }
    }
}
