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

//                let songDict = ["id": sID, "title": songTitle ?? sID, "artists": NSMutableArray(), "album": "",
//                                "releaseYear": "", "duration": duration, "lyrics": "", "tags": NSMutableArray(),
//                                "link": link, "fileExtension": newExtension] as [String : Any]

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
	
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case link = "link"
        case fileExt = "fileExtension"
        case title = "title"
        case artists = "artists"
        case album = "album"
        case releaseYear = "releaseYear"
        case duration = "duration"
        case lyrics = "lyrics"
        case tags = "tags"
    }
}

// MARK: Helpers

extension Song {
    
    // Syntax sugar meh
    static var emptySong: Self {
        return Song(id: "", title: "", link: "", duration: "", fileExt: "")
    }
    
    var artistsJoined: String {
        return artists.joined(separator: ", ")
    }
}
