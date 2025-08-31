//
//  PlaylistManager.swift
//  YouTag
//
//  Created by Youstanzr on 3/19/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}


class PlaylistManager: NSObject, PlaylistLibraryViewDelegate, NowPlayingViewDelegate {
    
    static let shared = PlaylistManager()  // Singleton instance

    private var lastAppliedChangeToken: Int = -1
    private var lastAppliedFilterSignature: String = ""
    // Helper to build a stable, order-insensitive signature string for PlaylistFilters
    private func makeFilterSignature(_ f: PlaylistFilters) -> String {
        // Build a stable, order-insensitive signature string for the filters
        func sortedJoined<T: CustomStringConvertible>(_ arr: [T]) -> String {
            arr.map { $0.description }.sorted().joined(separator: "|")
        }
        let tags = sortedJoined(f.tags)
        let artists = sortedJoined(f.artists)
        let albums = sortedJoined(f.albums)
        let ranges = sortedJoined(f.releaseYearRanges)
        let years = sortedJoined(f.releaseYears)
        let durations = sortedJoined(f.durations)
        return [tags, artists, albums, ranges, years, durations].joined(separator: "#")
    }

    enum FilterLogic { case and, or }

    var nowPlayingView: NowPlayingView!
    var playlistLibraryView: PlaylistLibraryView!
    var audioPlayer: YYTAudioPlayer!
    var playlistFilters = PlaylistFilters(tags: [], artists: [], albums: [], releaseYearRanges: [], releaseYears: [], durations: [])
    var currentPlaylist: [Song] = []
    var filterLogic: FilterLogic = .or

    override init() {
        super.init()
        audioPlayer = YYTAudioPlayer()
        playlistLibraryView = PlaylistLibraryView(frame: .zero, style: .plain)
        playlistLibraryView.PLDelegate = self
        nowPlayingView = NowPlayingView(frame: .zero, audioPlayer: audioPlayer)
        nowPlayingView.NPDelegate = self
    }
    
    // MARK: - Playlist Management
    
    func computePlaylistIfNeeded(mode: FilterLogic) {
        let token = LibraryManager.shared.changeToken
        let filtersSig = makeFilterSignature(playlistFilters)
        print("computePlaylistIfNeeded: token=\(token), filtersSig=\(filtersSig), mode=\(mode)")
        if token == lastAppliedChangeToken && filtersSig == lastAppliedFilterSignature && mode == filterLogic {
            // nothing changed → don’t touch playback
            return
        }
        // something changed → recompute
        computePlaylist(mode: mode)
    }

    
    func computePlaylist(mode: FilterLogic) {
        print("computePlaylist")
        self.filterLogic = mode
        let oldPlaylist = currentPlaylist

        let songs = LibraryManager.shared.getFilteredSongs(with: playlistFilters, mode: mode)
        // Filter out any songs whose file is missing
        let playableSongs = songs.filter { song in
            guard let url = LibraryManager.shared.urlForSong(song) else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }
        
        if samePlaylist(oldPlaylist, playableSongs) {
            // Same set of songs; keep old order to avoid jarring UI/audio changes
            let reordered = reorderToMatchOldOrder(newPlaylist: playableSongs, oldPlaylist: oldPlaylist)
            updatePlaylistLibrary(toPlaylist: reordered, uiOnly: true)
        } else {
            // Different contents; adopt the new playlist
            updatePlaylistLibrary(toPlaylist: playableSongs)
        }
        refreshStateTokens()
    }
    
    // Update baseline state to avoid redundant recomputes
    private func refreshStateTokens() {
        lastAppliedChangeToken = LibraryManager.shared.changeToken
        lastAppliedFilterSignature = makeFilterSignature(playlistFilters)
    }

    // Checks if two playlists are the same even if order is not the same
    private func samePlaylist(_ a: [Song], _ b: [Song]) -> Bool {
        guard a.count == b.count else { return false }
        guard !a.isEmpty else { return true }
        var counts: [String:Int] = [:]                // Song.id -> count
        for s in a { counts[s.id, default: 0] += 1 }
        for s in b {
            guard let c = counts[s.id], c > 0 else { return false }
            counts[s.id] = c - 1
        }
        return counts.values.allSatisfy { $0 == 0 }
    }
    
    private func reorderToMatchOldOrder(newPlaylist: [Song], oldPlaylist: [Song]) -> [Song] {
        guard newPlaylist.count == oldPlaylist.count else { return newPlaylist }
        // Map new songs by ID for quick lookup
        let mapNew: [String: Song] = Dictionary(uniqueKeysWithValues: newPlaylist.map { ($0.id, $0) })
        // Preserve the exact order from the old playlist
        return oldPlaylist.compactMap { mapNew[$0.id] }
    }

    func updatePlaylistLibrary(toPlaylist newPlaylist: [Song], uiOnly: Bool = false) {
        currentPlaylist = newPlaylist
        refreshPlaylistLibraryView(uiOnly: uiOnly)
    }
    
    // MARK: - Playlist Manipulation
    
    func refreshPlaylistLibraryView(uiOnly: Bool = false) {
        playlistLibraryView.refreshTableView()
        refreshNowPlayingView(uiOnly: uiOnly)
    }
    
    func didSelectSong(song: Song) {
        print("🎶 didSelectSong: \(song.title)")
        nowPlayingView.loadSong(song: song)
        audioPlayer.play()
    }
    
    func movePlaylistForward() {
        guard !currentPlaylist.isEmpty else { return }
        let lastSong = currentPlaylist.removeLast()
        currentPlaylist.insert(lastSong, at: 0)
        refreshPlaylistLibraryView()
    }
    
    func movePlaylistBackward() {
        guard !currentPlaylist.isEmpty else { return }
        let firstSong = currentPlaylist.removeFirst()
        currentPlaylist.append(firstSong)
        refreshPlaylistLibraryView()
    }
    
    func shufflePlaylist() {
        guard currentPlaylist.count > 1 else { return }
        let lastSong = currentPlaylist.removeLast()
        currentPlaylist.shuffle()
        currentPlaylist.append(lastSong)
        playlistLibraryView.refreshTableView()
        playlistLibraryView.scrollToTop()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()  // Haptic tap
    }
    
    // MARK: - Now Playing View Management
    func refreshNowPlayingView(uiOnly: Bool = false) {
        if let song = currentPlaylist.last {
            nowPlayingView.loadSong(song: song, preparePlayer: !uiOnly)  // prepare player only if we're not in UI-only mode
        } else {
            nowPlayingView.clearNowPlaying()
        }
    }

    // Called when the current track finishes playing
    func audioPlayerDidFinishTrack() {
        if audioPlayer.isSongRepeat {
            // Replay the same song
            if let song = currentPlaylist.last {
                _ = audioPlayer.play(song: song)
            }
        } else {
            // Advance to the next song
            movePlaylistForward()
            audioPlayer.play()
        }
    }
    
}
