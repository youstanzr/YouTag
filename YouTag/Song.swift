//
//  Song.swift
//  YouTag
//
//  Created by Youstanzr on 3/14/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation

struct SongTest {
    
}

/// Storing vars in structure allows swift (or xcode) to automatically create initializer for your struct
struct Song: Codable {
    
    let id: String
    var title: String
    var link: String
    
    // MARK: Optional properties
    
    var artists: [String] = []
    var album: String?
    var releaseYear: String = ""
    var duration: String
    var lyrics: String = ""
    var tags: [String] = []
    var fileExt: String
	
}

// MARK: Helpers

extension Song {
    
    // Syntax sugar meh
    static var emptySong: Self {
        return Song(id: "", title: "", link: "", duration: "", fileExt: "")
    }
    
    /// Helper to display artists as "artist, artist, artist"
    var artistsJoined: String {
        return artists.joined(separator: ", ")
    }
    
    /// Local image
    var imageUrl: URL? {
        return LocalFilesManager.getLocalFileURL(withNameAndExtension: id + ".jpg")
    }
    
    /// Local (cached) file's path
    var localUrl: URL? {
        return LocalFilesManager.getLocalFileURL(withNameAndExtension: id + "." + fileExt)
    }
    
}

// MARK: Legacy cache

extension Song {
    
    var cachePresentable: Dictionary<String, Any> {
        var presentable = Dictionary<String, Any>()
        
        MetadataExtractor.LocalSupportedMetadata.allCases.forEach { (key) in
            switch key {
            case .artist:
                presentable[key.cacheKey] = artists as NSArray
            case .title:
                presentable[key.cacheKey] = title
            case .album:
                presentable[key.cacheKey] = album
            case .year:
                presentable[key.cacheKey] = releaseYear
            case .tags:
                presentable[key.cacheKey] = tags as NSArray
            case .artwork:
                presentable[key.cacheKey] = ""
            case .id:
                presentable[key.cacheKey] = id
            case .link:
                presentable[key.cacheKey] = ""
            case .fileExtension:
                presentable[key.cacheKey] = fileExt
            case .lyrics:
                presentable[key.cacheKey] = lyrics
            case .duration:
                presentable[key.cacheKey] = duration
            case .unknown:
                break
            }
        }
        
        return presentable
    }
}
