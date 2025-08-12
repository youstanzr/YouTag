//
//  LibraryManager.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

enum ValueType {
    case min
    case max
}

class LibraryManager {

    static let shared = LibraryManager() // Singleton instance

    struct Constants {
        static let databaseName = "libraryDB.db"
        static let imageDirectory = "images"
    }

    var db: OpaquePointer?
    var libraryArray: [Song] = []

    private init() {
        print("LibraryManager initialized")
        setupDatabase()
        refreshLibraryArray()
    }

    deinit {
        closeDatabase()
    }
    
    func setupDatabase() {
        if db != nil { return }
        
        let fileManager = FileManager.default
        let appDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbPath = appDirectory.appendingPathComponent(Constants.databaseName).path

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            createTables()
        }
        createImageDirectory()
        print("Database path: \(dbPath)")
        enableForeignKeys()
    }
    
    func enableForeignKeys() {
        if sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("⚠️ Failed to enable foreign keys: \(errorMessage)")
        } else {
            print("✅ Foreign keys are enabled")
        }
    }
    
    func closeDatabase() {
        if db != nil {
            print("Closing database")
            sqlite3_close(db)
            db = nil
        } else {
            print("Database was already nil before closing")
        }
    }

    private func createTables() {
        let createSongsTableQuery = """
        CREATE TABLE IF NOT EXISTS Songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            album TEXT,
            releaseYear TEXT,
            duration TEXT,
            lyrics TEXT,
            filePath TEXT NOT NULL,
            thumbnailPath TEXT
        );
        """

        let createTagsTableQuery = """
        CREATE TABLE IF NOT EXISTS Tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tag_name TEXT UNIQUE NOT NULL
        );
        """

        let createSongTagsTableQuery = """
        CREATE TABLE IF NOT EXISTS SongTags (
            song_id TEXT,
            tag_id INTEGER,
            FOREIGN KEY(song_id) REFERENCES Songs(id) ON DELETE CASCADE,
            FOREIGN KEY(tag_id) REFERENCES Tags(id) ON DELETE CASCADE
        );
        """

        let createArtistsTableQuery = """
        CREATE TABLE IF NOT EXISTS Artists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist_name TEXT UNIQUE NOT NULL
        );
        """
        let createSongArtistsTableQuery = """
        CREATE TABLE IF NOT EXISTS SongArtists (
            song_id TEXT,
            artist_id INTEGER,
            FOREIGN KEY(song_id) REFERENCES Songs(id) ON DELETE CASCADE,
            FOREIGN KEY(artist_id) REFERENCES Artists(id) ON DELETE CASCADE
        );
        """

        var queries = [createSongsTableQuery, createTagsTableQuery, createSongTagsTableQuery]
        queries.append(contentsOf: [createArtistsTableQuery, createSongArtistsTableQuery])

        for query in queries {
            if sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Failed to execute query: \(query), Error: \(errorMessage)")
            }
        }
    }
    
    // MARK: - Refresh Library
    func refreshLibraryArray() {
        guard db != nil else {
            print("Error: Database is nil before executing query!")
            return
        }

        let fetchQuery = """
        SELECT id, title, album, releaseYear, duration, lyrics, filePath, thumbnailPath
        FROM Songs;
        """
        let songs = fetchSongs(from: fetchQuery)
        libraryArray = songs

        for song in libraryArray {
            if let url = urlForSong(song) {
                if (try? url.checkResourceIsReachable()) != true {
                    print("⚠️ Unreachable file for song \(song.title) (\(song.id))")
                }
            } else {
                print("⚠️ Invalid filePath for song \(song.title) (\(song.id))")
            }
        }
    }
    
    // MARK: - Fetch Songs
    func fetchSongs(from query: String) -> [Song] {
        var songs: [Song] = []
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let song = parseSong(from: statement) {
                    songs.append(song)
                }
            }
        }
        sqlite3_finalize(statement)
        return songs
    }

    /// Returns filtered songs based on PlaylistFilters, honoring AND/OR for tags, artists, release years & ranges, and durations.
    func getFilteredSongs(with filters: PlaylistFilters, mode: PlaylistManager.FilterLogic) -> [Song] {
        var query = """
        SELECT id, title, album, releaseYear, duration, lyrics, filePath, thumbnailPath
        FROM Songs
        WHERE 1=1 
        """

        // TAGS (AND/OR)
        if !filters.tags.isEmpty {
            let tagList = filters.tags.map { "'\($0)'" }.joined(separator: ", ")
            if mode == .or {
                query += """
                 AND id IN (
                     SELECT song_id FROM SongTags
                     WHERE tag_id IN (
                         SELECT id FROM Tags WHERE tag_name IN (\(tagList))
                     )
                 )
                 """
            } else {
                query += """
                 AND id IN (
                     SELECT st.song_id
                     FROM SongTags st
                     JOIN Tags t ON st.tag_id = t.id
                     WHERE t.tag_name IN (\(tagList))
                     GROUP BY st.song_id
                     HAVING COUNT(DISTINCT t.id) = \(filters.tags.count)
                 )
                 """
            }
        }

        // ARTISTS (AND/OR)
        if !filters.artists.isEmpty {
            let artistList = filters.artists.map { "'\($0)'" }.joined(separator: ", ")
            if mode == .or {
                query += """
                 AND id IN (
                     SELECT song_id FROM SongArtists
                     WHERE artist_id IN (
                         SELECT id FROM Artists WHERE artist_name IN (\(artistList))
                     )
                 )
                 """
            } else {
                query += """
                 AND id IN (
                     SELECT sa.song_id
                     FROM SongArtists sa
                     JOIN Artists a ON sa.artist_id = a.id
                     WHERE a.artist_name IN (\(artistList))
                     GROUP BY sa.song_id
                     HAVING COUNT(DISTINCT a.id) = \(filters.artists.count)
                 )
                 """
            }
        }

        // ALBUMS (always OR)
        if !filters.albums.isEmpty {
            let albumList = filters.albums.map { "'\($0)'" }.joined(separator: ", ")
            query += " AND album IN (\(albumList))"
        }

        // RELEASE YEARS + YEAR RANGES (AND/OR across both kinds)
        let parsedYears: [Int] = filters.releaseYears.compactMap { Int($0) }
        if mode == .or {
            var yearConds: [String] = []
            if !parsedYears.isEmpty {
                let yearList = parsedYears.map { String($0) }.joined(separator: ", ")
                yearConds.append("CAST(releaseYear AS INTEGER) IN (\(yearList))")
            } else if !filters.releaseYears.isEmpty {
                // fallback to string IN if non-numeric values exist
                let yearListStr = filters.releaseYears.map { "'\($0)'" }.joined(separator: ", ")
                yearConds.append("releaseYear IN (\(yearListStr))")
            }
            if !filters.releaseYearRanges.isEmpty {
                for range in filters.releaseYearRanges {
                    if range.count >= 2, let lower = range.first, let upper = range.last {
                        yearConds.append("CAST(releaseYear AS INTEGER) BETWEEN \(lower) AND \(upper)")
                    }
                }
            }
            if !yearConds.isEmpty {
                query += " AND (" + yearConds.joined(separator: " OR ") + ")"
            }
        } else { // AND mode => intersect constraints
            var hasConstraint = false
            var low = Int.min
            var high = Int.max

            let uniqueYears = Set(parsedYears)
            if !uniqueYears.isEmpty {
                if uniqueYears.count > 1 { return [] } // cannot be multiple distinct years simultaneously
                if let y = uniqueYears.first {
                    low = max(low, y)
                    high = min(high, y)
                    hasConstraint = true
                }
            }
            for range in filters.releaseYearRanges {
                if range.count >= 2, let rLow = range.first, let rHigh = range.last {
                    low = max(low, rLow)
                    high = min(high, rHigh)
                    hasConstraint = true
                }
            }
            if hasConstraint {
                if low > high { return [] }
                query += " AND CAST(releaseYear AS INTEGER) BETWEEN \(low) AND \(high)"
            }
        }

        // Execute base query
        let rawSongs = fetchSongs(from: query)

        // DURATIONS (AND/OR) — performed client-side since duration is stored as TEXT
        guard !filters.durations.isEmpty else { return rawSongs }

        if mode == .or {
            return rawSongs.filter { song in
                let duration = song.duration.convertToTimeInterval()
                guard !duration.isNaN else { return false }
                return filters.durations.contains { range in
                    guard range.count == 2 else { return false }
                    return duration >= range[0] && duration <= range[1]
                }
            }
        } else {
            // AND mode: intersect all ranges
            var low = -Double.infinity
            var high = Double.infinity
            var any = false
            for r in filters.durations {
                guard r.count == 2 else { continue }
                low = max(low, r[0])
                high = min(high, r[1])
                any = true
            }
            if !any { return rawSongs }
            if low > high { return [] }
            return rawSongs.filter { song in
                let duration = song.duration.convertToTimeInterval()
                guard !duration.isNaN else { return false }
                return duration >= low && duration <= high
            }
        }
    }

    func fetchSongsByTags(tags: [String]) -> [Song] {
        guard !tags.isEmpty else { return [] }

        let placeholders = tags.map { _ in "?" }.joined(separator: ", ")
        let query = """
        SELECT s.id, s.title, s.album, s.releaseYear, s.duration, s.lyrics, s.filePath, s.thumbnailPath
        FROM Songs s
        JOIN SongTags st ON s.id = st.song_id
        JOIN Tags t ON st.tag_id = t.id
        WHERE t.tag_name IN (\(placeholders))
        GROUP BY s.id
        HAVING COUNT(DISTINCT t.id) = ?;
        """

        var statement: OpaquePointer?
        var fetchedSongs: [Song] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            for (index, tag) in tags.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 1), tag, -1, transient)
            }
            sqlite3_bind_int(statement, Int32(tags.count + 1), Int32(tags.count))

            while sqlite3_step(statement) == SQLITE_ROW {
                if let song = parseSong(from: statement) {
                    fetchedSongs.append(song)
                }
            }
        }
        sqlite3_finalize(statement)
        return fetchedSongs
    }

    func getTagsForSong(id: String) -> [String] {
        var tags: [String] = []
        let query = """
        SELECT t.tag_name FROM Tags t
        JOIN SongTags st ON t.id = st.tag_id
        WHERE st.song_id = ?
        ORDER BY t.tag_name;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, id, -1, transient)
            while sqlite3_step(statement) == SQLITE_ROW {
                if let tagNameC = sqlite3_column_text(statement, 0) {
                    tags.append(String(cString: tagNameC))
                }
            }
        }
        sqlite3_finalize(statement)
        return tags
    }

    func getArtistsForSong(id: String) -> [String] {
        var artists: [String] = []
        let query = """
        SELECT a.artist_name FROM Artists a
        JOIN SongArtists sa ON a.id = sa.artist_id
        WHERE sa.song_id = ?
        ORDER BY a.artist_name;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, id, -1, transient)
            while sqlite3_step(statement) == SQLITE_ROW {
                if let artistNameC = sqlite3_column_text(statement, 0) {
                    artists.append(String(cString: artistNameC))
                }
            }
        }
        sqlite3_finalize(statement)
        return artists
    }

    func getAllDistinctValues(for column: String) -> [String] {
        var resultList: [String] = []
        var query: String

        if column == "tags" {
            query = "SELECT DISTINCT tag_name FROM Tags ORDER BY tag_name"
        } else if column == "artists" {
            query = "SELECT DISTINCT artist_name FROM Artists ORDER BY artist_name"
        } else {
            query = "SELECT DISTINCT \(column) FROM Songs ORDER BY \(column)"
        }
        
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cText = sqlite3_column_text(statement, 0) {
                    let text = String(cString: cText)
                    // Skip null or empty values
                    if !text.isEmpty {
                        resultList.append(text)
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return Array(Set(resultList)) // Remove duplicates
    }
    
    
    func getDuration(_ type: ValueType) -> Double {
        guard !libraryArray.isEmpty else { return 0 }
        
        let durations = libraryArray.compactMap { $0.duration.convertToTimeInterval() }
        
        switch type {
            case .min:
                return durations.min() ?? 0
            case .max:
                return durations.max() ?? 0
        }
    }

    func getReleaseYear(_ type: ValueType) -> Int {
        guard !libraryArray.isEmpty else { return 0 }
        
        let releaseYears = libraryArray.compactMap { song -> Int? in
            if let releaseYear = song.releaseYear, let year = Int(releaseYear) {
                return year
            }
            return nil
        }
        
        switch type {
            case .min:
                return releaseYears.min() ?? 0
            case .max:
                return releaseYears.max() ?? 0
        }
    }

    func fetchThumbnail(for song: Song) -> UIImage? {
        // 1. Bail out if we don’t have a filename
        guard let filename = song.thumbnailPath, !filename.isEmpty else {
            return nil
        }
        // 2. Compute the full URL via your helper
        let fileURL = LocalFilesManager.getImageFileURL(for: filename)
        // 3. Load if it’s really there
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // MARK: - Parsing Helpers
    private func parseSong(from statement: OpaquePointer?) -> Song? {
        guard let statement = statement else { return nil }

        func getColumnText(_ index: Int32) -> String {
            guard let text = sqlite3_column_text(statement, index) else { return "" }
            return String(cString: text)
        }

        let id = getColumnText(0)
        let title = getColumnText(1)
        let album = getColumnText(2)
        let releaseYear = getColumnText(3)
        let duration = getColumnText(4)
        let lyrics = getColumnText(5)

        // filePath at index 6
        let filePath = getColumnText(6).isEmpty ? nil : getColumnText(6)
        let thumbnailPath = getColumnText(7).isEmpty ? nil : getColumnText(7)

        // Fetch tags and artists
        let tags = getTagsForSong(id: id)
        let artists = getArtistsForSong(id: id)

        return Song(
            id: id,
            title: title,
            artists: artists,
            album: album.isEmpty ? nil : album,
            releaseYear: releaseYear.isEmpty ? nil : releaseYear,
            duration: duration,
            lyrics: lyrics.isEmpty ? nil : lyrics,
            filePath: filePath,
            thumbnailPath: thumbnailPath,
            tags: tags
        )
    }

    
    // MARK: - Add Song
    func addSongToLibrary(song: Song) {
        let insertSongQuery = """
        INSERT INTO Songs (id, title, album, releaseYear, duration, lyrics, filePath, thumbnailPath)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        print(
            "🔍 Attempting to Insert:",
            "- ID: \(song.id)",
            "- Title: \(song.title)",
            "- Artists: \(song.artists.joined(separator: ", "))",
            "- Album: \(song.album ?? "NULL")",
            "- Release Year: \(song.releaseYear ?? "NULL")",
            "- Duration: \(song.duration)",
            "- Tags: \(song.tags.joined(separator: ", "))",
            "- Lyrics: \(song.lyrics ?? "NULL")",
            "- Thumbnail Path: \(song.thumbnailPath ?? "NULL")",
            "- FilePath: \(song.filePath ?? "NULL")"
        )

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertSongQuery, -1, &statement, nil) == SQLITE_OK {
            bindSongData(statement, song)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Successfully inserted song.")
                libraryArray.append(song)
                addTagsToSong(songID: song.id, tags: song.tags)
                addArtistsToSong(songID: song.id, artists: song.artists)
            } else {
                print("❌ Error inserting song: \(sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error")")
            }
        } else {
            print("❌ SQL Statement Error: \(sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error")")
        }

        sqlite3_finalize(statement)
    }
    
    private func bindSongData(_ statement: OpaquePointer?, _ song: Song) {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, song.id, -1, transient)
        sqlite3_bind_text(statement, 2, song.title, -1, transient)
        sqlite3_bind_text(statement, 3, song.album ?? "", -1, transient)
        sqlite3_bind_text(statement, 4, song.releaseYear ?? "", -1, transient)
        let formattedDuration = song.duration.convertToTimeInterval().formattedString()
        sqlite3_bind_text(statement, 5, formattedDuration, -1, transient)
        sqlite3_bind_text(statement, 6, song.lyrics ?? "", -1, transient)
        sqlite3_bind_text(statement, 7, song.filePath ?? "", -1, transient)
        sqlite3_bind_text(statement, 8, song.thumbnailPath ?? "", -1, transient)
    }
    
    private func addTagsToSong(songID: String, tags: [String]) {
        let insertTagQuery = "INSERT INTO Tags (tag_name) VALUES (?) ON CONFLICT(tag_name) DO NOTHING RETURNING id;"
        let linkSongTagQuery = "INSERT INTO SongTags (song_id, tag_id) VALUES (?, ?);"

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for tag in tags {
            var tagStatement: OpaquePointer?
            var tagID: Int32 = -1  // Default invalid ID

            if sqlite3_prepare_v2(db, insertTagQuery, -1, &tagStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(tagStatement, 1, tag, -1, transient)
                if sqlite3_step(tagStatement) == SQLITE_ROW {  // If we get a result row, fetch the new tag ID
                    tagID = sqlite3_column_int(tagStatement, 0)
                }
            }
            sqlite3_finalize(tagStatement)

            // If no ID was returned, retrieve existing tag ID
            if tagID == -1 {
                let selectTagIDQuery = "SELECT id FROM Tags WHERE tag_name = ?;"
                if sqlite3_prepare_v2(db, selectTagIDQuery, -1, &tagStatement, nil) == SQLITE_OK {
                    sqlite3_bind_text(tagStatement, 1, tag, -1, transient)
                    if sqlite3_step(tagStatement) == SQLITE_ROW {
                        tagID = sqlite3_column_int(tagStatement, 0)
                    }
                }
                sqlite3_finalize(tagStatement)
            }

            // If tagID is valid, insert into SongTags
            if tagID != -1 {
                var linkStatement: OpaquePointer?
                if sqlite3_prepare_v2(db, linkSongTagQuery, -1, &linkStatement, nil) == SQLITE_OK {
                    sqlite3_bind_text(linkStatement, 1, songID, -1, transient)
                    sqlite3_bind_int(linkStatement, 2, tagID)
                    sqlite3_step(linkStatement)
                }
                sqlite3_finalize(linkStatement)
            }
        }
    }

    private func addArtistsToSong(songID: String, artists: [String]) {
        let insertArtistSQL = "INSERT OR IGNORE INTO Artists (artist_name) VALUES (?);"
        let selectArtistIDSQL = "SELECT id FROM Artists WHERE artist_name = ?;"
        let linkSongArtistSQL = "INSERT OR IGNORE INTO SongArtists (song_id, artist_id) VALUES (?, ?);"

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for raw in artists {
            let artist = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !artist.isEmpty else {
                print("⚠️ Skipping empty artist name for song \(songID)")
                continue
            }

            // 1) Insert or ignore artist
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, insertArtistSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, artist, -1, transient)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)

            // 2) Look up its ID
            var artistID: Int32 = -1
            if sqlite3_prepare_v2(db, selectArtistIDSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, artist, -1, transient)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    artistID = sqlite3_column_int(stmt, 0)
                }
            }
            sqlite3_finalize(stmt)

            guard artistID != -1 else {
                print("❌ Artist '\(artist)' could not be found/created.")
                continue
            }

            // 3) Link to song
            if sqlite3_prepare_v2(db, linkSongArtistSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, songID, -1, transient)
                sqlite3_bind_int(stmt, 2, artistID)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    
    // MARK: - Update Song
    func updateSongDetails(song: Song) {
        let query = """
        UPDATE Songs
        SET title = ?, album = ?, releaseYear = ?, duration = ?, lyrics = ?, filePath = ?, thumbnailPath = ?
        WHERE id = ?;
        """
        
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, song.title, -1, transient)
            sqlite3_bind_text(statement, 2, song.album ?? "", -1, transient)
            sqlite3_bind_text(statement, 3, song.releaseYear ?? "", -1, transient)
            let formattedDuration = song.duration.convertToTimeInterval().formattedString()
            sqlite3_bind_text(statement, 4, formattedDuration, -1, transient)
            sqlite3_bind_text(statement, 5, song.lyrics ?? "", -1, transient)
            sqlite3_bind_text(statement, 6, song.filePath ?? "", -1, transient)
            sqlite3_bind_text(statement, 7, song.thumbnailPath ?? "", -1, transient)
            sqlite3_bind_text(statement, 8, song.id, -1, transient)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)

        resetArtists(for: song.id, to: song.artists)
        resetTags(for: song.id, to: song.tags)
        
        purgeUnusedTags()
        purgeUnusedArtists()
    }
    

    // MARK: - Delete Song
    func deleteSongFromLibrary(songID: String) {
        print("Delete song \(songID)")

        // 1. Fetch filePath for the song
        var filePathToDelete: String?
        let selectFilePathQuery = "SELECT filePath FROM Songs WHERE id = ?;"
        var stmt: OpaquePointer?
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        if sqlite3_prepare_v2(db, selectFilePathQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, songID, -1, transient)
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cstr = sqlite3_column_text(stmt, 0) {
                    filePathToDelete = String(cString: cstr)
                }
            }
        }
        sqlite3_finalize(stmt)

        let deleteSongQuery = "DELETE FROM Songs WHERE id = ?;"
        let deleteSongTagsQuery = "DELETE FROM SongTags WHERE song_id = ?;"
        let deleteSongArtistsQuery = "DELETE FROM SongArtists WHERE song_id = ?;"

        var statement: OpaquePointer?

        // Delete SongTags links
        if sqlite3_prepare_v2(db, deleteSongTagsQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, songID, -1, transient)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)

        // Delete SongArtists links
        if sqlite3_prepare_v2(db, deleteSongArtistsQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, songID, -1, transient)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)

        // Delete the Song row
        if sqlite3_prepare_v2(db, deleteSongQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, songID, -1, transient)
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE {
                let deletedRows = sqlite3_changes(db)
                print("✅ Deleted \(deletedRows) row(s) from Songs.")
            }
        }
        sqlite3_finalize(statement)

        // 2. Remove the actual file from Documents/Songs
        if let filePath = filePathToDelete, !filePath.isEmpty {
            let fileURL = LocalFilesManager.getSongFileURL(for: filePath)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("🗑️ Removed song file at \(fileURL.path)")
                } catch {
                    print("⚠️ Error removing song file at \(fileURL.path): \(error)")
                }
            }
        }

        purgeUnusedTags()
        purgeUnusedArtists()
    }
    
    private func resetArtists(for songID: String, to artists: [String]) {
        let deleteArtistsQuery = "DELETE FROM SongArtists WHERE song_id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteArtistsQuery, -1, &stmt, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(stmt, 1, songID, -1, transient)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        addArtistsToSong(songID: songID, artists: artists)
    }

    private func resetTags(for songID: String, to tags: [String]) {
        let deleteTagsQuery = "DELETE FROM SongTags WHERE song_id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteTagsQuery, -1, &stmt, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(stmt, 1, songID, -1, transient)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        addTagsToSong(songID: songID, tags: tags)
    }

    
    // MARK: - Purge Unused Tags and Artists
    private func purgeUnusedTags() {
        let purgeTagsSQL = """
        DELETE FROM Tags
        WHERE id NOT IN (SELECT DISTINCT tag_id FROM SongTags);
        """
        if sqlite3_exec(db, purgeTagsSQL, nil, nil, nil) != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(db))
            print("⚠️ Error purging unused tags: \(errMsg)")
        }
    }

    private func purgeUnusedArtists() {
        let purgeArtistsSQL = """
        DELETE FROM Artists
        WHERE id NOT IN (SELECT DISTINCT artist_id FROM SongArtists);
        """
        if sqlite3_exec(db, purgeArtistsSQL, nil, nil, nil) != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(db))
            print("⚠️ Error purging unused artists: \(errMsg)")
        }
    }

    
    // MARK: - Handle Missing Files
    func handleMissingFiles() -> [Song] {
        return libraryArray.filter { song in
            guard let url = urlForSong(song) else { return false }
            return !FileManager.default.fileExists(atPath: url.path)
        }
    }

    // MARK: - Security-Scoped URL Helper
    func urlForSong(_ song: Song) -> URL? {
        guard let fileName = song.filePath,
              !fileName.isEmpty else {
            print("❌ Missing filePath for song \(song.id)")
            return nil
        }
        let url = LocalFilesManager.getSongFileURL(for: fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    // MARK: - Metadata Enrichment
    func enrichSong(fromMetadata metadata: [String: Any], for song: Song) -> Song {
        var enrichedSong = song

        for (key, value) in metadata {
            let propertyKey = getKey(forMetadataKey: key)
            switch propertyKey {
            case "title":
                if let stringValue = value as? String, !stringValue.isEmpty {
                    if enrichedSong.title.isEmpty || enrichedSong.title == enrichedSong.id {
                        enrichedSong.title = stringValue
                    }
                }
            case "artist":
                if let stringValue = value as? String, !stringValue.isEmpty {
                    if !enrichedSong.artists.contains(stringValue) {
                        enrichedSong.artists.append(stringValue)
                    }
                }
            case "album":
                if let stringValue = value as? String, !stringValue.isEmpty {
                    if enrichedSong.album?.isEmpty ?? true {
                        enrichedSong.album = stringValue
                    }
                }
            case "year":
                if let stringValue = value as? String, !stringValue.isEmpty {
                    if enrichedSong.releaseYear?.isEmpty ?? true {
                        enrichedSong.releaseYear = stringValue
                    }
                }
            case "type":
                if let stringValue = value as? String, !stringValue.isEmpty {
                    if !enrichedSong.tags.contains(stringValue) {
                        enrichedSong.tags.append(stringValue)
                    }
                }
            case "artwork":
                // Save album artwork to local images directory and update thumbnailPath
                if let imageData = value as? Data,
                   let image = UIImage(data: imageData),
                   let fileURL = LocalFilesManager.saveImage(image, withName: enrichedSong.id) {
                    // Store only the filename so fetchThumbnail uses getImageFileURL
                    enrichedSong.thumbnailPath = fileURL.lastPathComponent
                }
            default:
                break
            }
        }
        
        return enrichedSong
    }
    private func getKey(forMetadataKey mdKey: String) -> String {
        switch mdKey {
        case "title", "songName", "TIT2":
            return "title"
        case "artist", "TPE1":
            return "artist"
        case "album", "albumName", "TIT1", "TALB":
            return "album"
        case "year", "TYER", "TDAT", "TORY", "TDOR":
            return "year"
        case "type", "TCON":
            return "type"
        case "artwork", "APIC":
            return "artwork"
        default:
            return mdKey
        }
    }
    private func createImageDirectory() {
        let fileManager = FileManager.default
        let appDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesURL = appDirectory.appendingPathComponent(Constants.imageDirectory)
        if !fileManager.fileExists(atPath: imagesURL.path) {
            do {
                try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("⚠️ Error creating images directory: \(error)")
            }
        }
    }
}

