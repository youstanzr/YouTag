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

    var nowPlayingView: NowPlayingView!
    var playlistLibraryView: PlaylistLibraryView!
    var audioPlayer: YYTAudioPlayer!
    var playlistFilters = PlaylistFilters(tags: [], artists: [], albums: [], releaseYearRanges: [], releaseYears: [], durations: [])
    var currentPlaylist: [Song] = []

    override init() {
        super.init()
        audioPlayer = YYTAudioPlayer()
        playlistLibraryView = PlaylistLibraryView(frame: .zero, style: .plain)
        playlistLibraryView.PLDelegate = self
        nowPlayingView = NowPlayingView(frame: .zero, audioPlayer: audioPlayer)
        nowPlayingView.NPDelegate = self
    }
    
    // MARK: - Playlist Management
    func computePlaylist() {
        let songs = LibraryManager.shared.getFilteredSongs(with: playlistFilters)
        // Filter out any songs whose file is missing
        let playableSongs = songs.filter { song in
            guard let url = LibraryManager.shared.urlForSong(song) else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }
        updatePlaylistLibrary(toPlaylist: playableSongs)
    }

    func updatePlaylistLibrary(toPlaylist newPlaylist: [Song]) {
        currentPlaylist = newPlaylist
        playlistLibraryView.refreshTableView()
        refreshNowPlayingView()
    }
    
    // MARK: - Playlist Manipulation
    
    func refreshPlaylistLibraryView() {
        playlistLibraryView.refreshTableView()
        refreshNowPlayingView()
    }
    
    func didSelectSong(song: Song) {
        print("🎶 didSelectSong: \(song.title)")
        nowPlayingView.loadSong(song: song)
        refreshNowPlayingView()
        audioPlayer.play()
    }
    
    func movePlaylistForward() {
        let lastSong = currentPlaylist.removeLast()
        currentPlaylist.insert(lastSong, at: 0)
        refreshPlaylistLibraryView()
    }
    
    func movePlaylistBackward() {
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
    }
    
    // MARK: - Now Playing View Management
    func refreshNowPlayingView() {
        if let song = currentPlaylist.last {
            nowPlayingView.loadSong(song: song)  // Will play the song after loading it
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
