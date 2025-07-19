//
//  PlaylistFilters.swift
//  YouTag
//
//  Created by Youstanzr on 3/25/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation

struct PlaylistFilters {
    
    enum FilterType: String {
        case tag = "tags"
        case artist = "artist"
        case album = "album"
        case releaseYearRange = "releaseYearRange"
        case releaseYear = "releaseYear"
        case duration = "duration"
    }

    var tags: [String] = []
    var artists: [String] = []
    var albums: [String] = []
    var releaseYearRanges: [[Int]] = []
    var releaseYears: [Int] = []
    var durations: [[TimeInterval]] = []
    
    // MARK: - Retrieve Filters
    func getFilters() -> [[String]] {
        var resultArr: [[String]] = []
        // Tags
        for tag in tags {
            resultArr.append([FilterType.tag.rawValue, tag])
        }
        // Artists
        for artist in artists {
            resultArr.append([FilterType.artist.rawValue, artist])
        }
        // Albums
        for album in albums {
            resultArr.append([FilterType.album.rawValue, album])
        }
        // Release Year Ranges
        for range in releaseYearRanges where range.count == 2 {
            let value = "\(range[0]) - \(range[1])"
            resultArr.append([FilterType.releaseYearRange.rawValue, value])
        }
        // Release Years
        for year in releaseYears {
            resultArr.append([FilterType.releaseYear.rawValue, "\(year)"])
        }
        // Durations
        for durationRange in durations where durationRange.count == 2 {
            let lower = durationRange[0].formattedString()
            let upper = durationRange[1].formattedString()
            let value = "\(lower) - \(upper)"
            resultArr.append([FilterType.duration.rawValue, value])
        }
        return resultArr
    }
            
    // MARK: - Delete Filters
    mutating func deleteFilter(type: FilterType, value: Any) {
        switch type {
        case .tag:
            if let val = value as? String { tags.removeAll { $0 == val } }
        case .artist:
            if let val = value as? String { artists.removeAll { $0 == val } }
        case .album:
            if let val = value as? String { albums.removeAll { $0 == val } }
        case .releaseYearRange:
            if let str = value as? String {
                let parts = str.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespaces) }
                releaseYearRanges.removeAll { $0 == [Int(parts[0]), Int(parts[1])] }
            }
        case .releaseYear:
            if let year = Int(value as! String) { releaseYears.removeAll { $0 == year } }
        case .duration:
            if let str = value as? String {
                let parts = str.components(separatedBy: " - ")
                let times = parts.map { $0.convertToTimeInterval() }
                // Remove any entry equal to this pair
                durations.removeAll { $0 == times }
            }
        }
    }

    // MARK: - Add Unique Filters
    
    mutating func addUniqueFilter(type: FilterType, values: [Any]) {
        switch type {
        case .tag:
            var newTags = tags
            addUniqueStrings(&newTags, values: values as? [String] ?? [])
            tags = newTags
        case .artist:
            var newArtists = artists
            addUniqueStrings(&newArtists, values: values as? [String] ?? [])
            artists = newArtists
        case .album:
            var newAlbums = albums
            addUniqueStrings(&newAlbums, values: values as? [String] ?? [])
            albums = newAlbums
        case .releaseYearRange:
            var newReleaseYearRanges = releaseYearRanges
            addUniqueRanges(&newReleaseYearRanges, values: [values.compactMap { $0 as? Int }])
            releaseYearRanges = newReleaseYearRanges
        case .releaseYear:
            var newReleaseYears = releaseYears
            addUniqueInts(&newReleaseYears, values: values as? [Int] ?? [])
            releaseYears = newReleaseYears
        case .duration:
            var newDurations = durations
            addUniqueRanges(&newDurations, values: values as? [[TimeInterval]] ?? [])
            durations = newDurations
        }
    }
        
    // MARK: - Helper Methods
    
    private mutating func addUniqueStrings(_ target: inout [String], values: [String]) {
        for value in values where !target.contains(value) {
            target.append(value)
        }
    }
    
    private mutating func addUniqueInts(_ target: inout [Int], values: [Int]) {
        for value in values where !target.contains(value) {
            target.append(value)
        }
    }
    
    private mutating func addUniqueRanges<T: Equatable>(_ target: inout [[T]], values: [[T]]) {
        for value in values where !target.contains(value) {
            target.append(value)
        }
    }
    
}

// MARK: - TimeInterval Extension for Formatting

extension TimeInterval {
    func formattedString() -> String {
        let time = NSInteger(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
}
