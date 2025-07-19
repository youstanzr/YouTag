//
//  Song.swift
//  YouTag
//
//  Created by Youstanzr on 3/14/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation

struct Song: Codable, Equatable {
    var title: String
    var artists: [String]
    var id: String
    var duration: String
    var tags: [String]
    var album: String?
    var releaseYear: String?
    var lyrics: String?
    var thumbnailPath: String?
    var fileBookmark: Data?
    
    // Default initializer
    init() {
        self.title = ""
        self.artists = []
        self.id = ""
        self.duration = ""
        self.tags = []
        self.album = nil
        self.releaseYear = nil
        self.lyrics = nil
        self.thumbnailPath = nil
        self.fileBookmark = nil
    }
    
    // Custom initializer
    init(id: String, title: String, artists: [String] = [], album: String? = nil, releaseYear: String? = nil, duration: String, lyrics: String? = nil, fileBookmark: Data? = nil, thumbnailPath: String? = nil, tags: [String] = []) {
        self.id = id
        self.title = title
        self.artists = artists
        self.album = album
        self.releaseYear = releaseYear
        self.duration = duration
        self.lyrics = lyrics
        self.fileBookmark = fileBookmark
        self.thumbnailPath = thumbnailPath
        self.tags = tags
    }
    
    static func from(url: URL) -> Song {
        let fileName = url.deletingPathExtension().lastPathComponent
        let bookmark: Data? = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        
        return Song(
            id: UUID().uuidString,
            title: fileName,
            artists: [],
            album: nil,
            releaseYear: nil,
            duration: "",
            lyrics: nil,
            fileBookmark: bookmark,
            thumbnailPath: nil,
            tags: []
        )
    }
}
