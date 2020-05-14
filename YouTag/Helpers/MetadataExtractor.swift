//
//  MetadataExtractor.swift
//  YouTag
//
//  Created by spooky on 5/14/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation
import AVFoundation

class MetadataExtractor {
    
    enum ExtractorError: Error {
        
        case notSupported(key: String)
    }
    
    enum LocalSupportedMetadata: String {
        
        case artist = "artists"
        case title
        case album
        case year = "releaseYear"
        case tags
        case artwork
        case unknown
        case id
        case link
        case fileExtension
        case lyrics
        case duration
        
        var cacheKey: String { rawValue }
    }
    
    /// Used to extract metadata from external resources to dictionary
    static func extractSongMetadata(songID: String, songExtension: String) -> Dictionary<String, Any> {
        var dict = Dictionary<String, Any>()
        let asset = AVAsset(url: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).\(songExtension)"))
        for item in asset.metadata {
            guard let key = item.commonKey?.rawValue ?? item.key?.description, let value = item.value else {
                continue
            }
            dict[key] = value
        }
        return dict
    }
    
    /// Used to transform metadata into local supported metadata
    static func parseToSupported(from metadata: String) throws -> LocalSupportedMetadata {
        switch metadata {
            case "title",
                 "songName",
                 "TIT2":
                
                return .title
            case "artist",
                 "TPE1":
                
                return .artist
            case "albumName",
                 "album",
                 "TIT1",
                 "TALB":
                
                return .artwork
            case "type",
                 "TCON":
                
                return .tags
            case "year",
                 "TYER",
                 "TDAT",
                 "TORY",
                 "TDOR":
                
                return .year
            case "artwork",
                 "APIC":
                
                return .artwork
            default:
                throw ExtractorError.notSupported(key: metadata)
        }
    }
}
