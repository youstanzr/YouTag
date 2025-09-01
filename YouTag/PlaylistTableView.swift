//
//  PlaylistTableView.swift
//  YouTag
//
//  Created by Youstanzr on 2/29/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

protocol PlaylistLibraryViewDelegate: AnyObject {
    func didSelectSong(song: Song)
}

class PlaylistTableView: LibraryTableView, UITableViewDragDelegate, UITableViewDropDelegate {

    weak var PLDelegate: PlaylistLibraryViewDelegate?

    private var longPressValues: (indexPath: IndexPath?, cellSnapShot: UIView?) = (nil, nil)
    
    // MARK: - Initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.dragInteractionEnabled = true
        self.dragDelegate = self
        self.dropDelegate = self
    }

    // MARK: - Index Mapping Helpers
    private func playlistIndex(forVisible indexPath: IndexPath) -> Int {
        // Visible rows show everything except the current (last). Visible 0 == second-to-last
        let count = PlaylistManager.shared.currentPlaylist.count
        return (count - 2 - indexPath.row) % max(count, 1)
    }

    private func visibleIndexPath(forPlaylistIndex pIndex: Int) -> IndexPath? {
        // Map a playlist index (0..count-1) to a visible row (0..count-2). Return nil for the current (last)
        let count = PlaylistManager.shared.currentPlaylist.count
        guard count > 1, pIndex >= 0, pIndex < count - 1 else { return nil }
        let row = (count - 2 - pIndex)
        return IndexPath(row: row, section: 0)
    }

    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let idx = playlistIndex(forVisible: indexPath)
        let song = PlaylistManager.shared.currentPlaylist[idx]
        let item = UIDragItem(itemProvider: NSItemProvider())
        item.localObject = song
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        session.localContext = tableView
        return [item]
    }

    // MARK: - UITableViewDropDelegate
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        // Only handle local drags that originated from this same table view
        if let local = session.localDragSession, (local.localContext as? UITableView) === tableView { return true }
        return false
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Only allow in-table reordering; show insertion placeholder
        if let local = session.localDragSession, (local.localContext as? UITableView) === tableView {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let song = item.dragItem.localObject as? Song else { return }

        var playlist = PlaylistManager.shared.currentPlaylist
        let count = playlist.count
        guard count > 1 else { return }

        guard let fromIndex = playlist.firstIndex(where: { $0.id == song.id }) else { return }

        // Destination: if nil, fall back to the original visible position (no-op)
        let destIndexPath = coordinator.destinationIndexPath
            ?? visibleIndexPath(forPlaylistIndex: fromIndex)
            ?? IndexPath(row: 0, section: 0)

        let toIndex = playlistIndex(forVisible: destIndexPath)
        let clampedTo = min(max(toIndex, 0), count - 2)
        if fromIndex == clampedTo {
            // No-op drop (same position)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        // Snapshot animation endpoints BEFORE mutating the data source
        let fromVisible = visibleIndexPath(forPlaylistIndex: fromIndex)
        let toVisible = visibleIndexPath(forPlaylistIndex: clampedTo)

        // Apply model change and animate move
        tableView.performBatchUpdates({
            let moved = playlist.remove(at: fromIndex)
            playlist.insert(moved, at: clampedTo)
            PlaylistManager.shared.currentPlaylist = playlist
            if let fv = fromVisible, let tv = toVisible {
                tableView.moveRow(at: fv, to: tv)
            } else {
                tableView.reloadData()
            }
        }, completion: { _ in
            PlaylistManager.shared.refreshNowPlayingView(uiOnly: true)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
    }

    // MARK: - Swipe Actions (Right swipe)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let adjustedIndex = playlistIndex(forVisible: indexPath)
        let song = PlaylistManager.shared.currentPlaylist[adjustedIndex]

        let playNextAction = UIContextualAction(style: .normal, title: "Play Next") { [weak self] _, _, completion in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.playNext(song: song)
            completion(true)
        }

        let config = UISwipeActionsConfiguration(actions: [playNextAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    // MARK: - Actions
    private func play(song: Song) {
        // Rotate playlist so selected song plays last
        if !PlaylistManager.shared.currentPlaylist.isEmpty {
            if let last = PlaylistManager.shared.currentPlaylist.last {
                PlaylistManager.shared.currentPlaylist.insert(last, at: 0)
                PlaylistManager.shared.currentPlaylist.removeLast()
            }
            PlaylistManager.shared.currentPlaylist.removeAll { $0.id == song.id }
        }
        PlaylistManager.shared.currentPlaylist.append(song)

        // Refresh playlist UI and kick playback
        PlaylistManager.shared.playlistTableView.refreshTableView()
        self.PLDelegate?.didSelectSong(song: song)
    }

    private func playNext(song: Song) {
        guard !PlaylistManager.shared.currentPlaylist.isEmpty else { return }
        let count = PlaylistManager.shared.currentPlaylist.count
        if let idx = PlaylistManager.shared.currentPlaylist.firstIndex(where: { $0.id == song.id }) {
            if idx == count - 1 { return } // already current
            let s = PlaylistManager.shared.currentPlaylist.remove(at: idx)
            let insertIndex = max(PlaylistManager.shared.currentPlaylist.count - 1, 0) // second-to-last
            let safeIndex = min(insertIndex, PlaylistManager.shared.currentPlaylist.count)
            PlaylistManager.shared.currentPlaylist.insert(s, at: safeIndex)
        } else {
            let insertIndex = max(count - 1, 0)
            let safeIndex = min(insertIndex, PlaylistManager.shared.currentPlaylist.count)
            PlaylistManager.shared.currentPlaylist.insert(song, at: safeIndex)
        }
        // Lightweight UI refresh
        PlaylistManager.shared.playlistTableView.reloadData()
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

        let adjustedIndex = playlistIndex(forVisible: indexPath)
        let song = PlaylistManager.shared.currentPlaylist[adjustedIndex]
        
        cell.refreshCell(with: song, showTags: true)
        return cell
    }

    // MARK: - UITableView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let adjustedIndex = playlistIndex(forVisible: indexPath)
        let song = PlaylistManager.shared.currentPlaylist[adjustedIndex]
        print("Selected cell number \(indexPath.row) -> \(song.title)")
        play(song: song)
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let adjustedIndex = playlistIndex(forVisible: indexPath)
            PlaylistManager.shared.currentPlaylist.remove(at: adjustedIndex)
            tableView.reloadData()
        }
    }
    
    // MARK: - Drag/Drop Preview Appearance
    // Make the drag lift highlight transparent
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let params = UIDragPreviewParameters()
        params.backgroundColor = GraphicColors.alpha50Gray
        return params
    }

    // Make the drop preview highlight transparent
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let params = UIDragPreviewParameters()
        params.backgroundColor = GraphicColors.alpha50Gray
        return params
    }
}
