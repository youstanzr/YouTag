//
//  LocalFilesManager.swift
//  YouTag
//
//  Created by Youstanzr on 3/1/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit
import AVFoundation

class LocalFilesManager {
    
    // MARK: - File Paths
    /// Get the file URL for metadata storage (DB, images) in the app’s directory
    static func getMetadataFileURL(for fileName: String) -> URL {
        let appDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return appDirectory.appendingPathComponent(fileName)
    }

    // MARK: - File Operations
    
    /// Get the size of a file as a formatted string
    static func getLocalFileSize(fileURL: URL) -> String {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attr[FileAttributeKey.size] as! UInt64
            return ByteCountFormatter().string(fromByteCount: Int64(bitPattern: fileSize))
        } catch {
            print("Error @getLocalFileSize: \(error.localizedDescription)")
            return ""
        }
    }

    /// Check if a file exists at a given path
    static func checkFileExist(_ fileURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Delete a file
    static func deleteFile(at fileURL: URL) -> Bool {
        if checkFileExist(fileURL) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("Removed file: \(fileURL.path)")
                return true
            } catch let removeError {
                print("Couldn't remove file at path", removeError.localizedDescription)
                return false
            }
        }
        return false
    }

    
    // MARK: - Metadata Extraction
    
    /// Extract duration of a media file
    static func extractDurationForSong(fileURL: URL) async -> String {
        let asset = AVAsset(url: fileURL)
        do {
            // Load duration using async/await
            let duration: CMTime = try await asset.load(.duration)
            return TimeInterval(duration.seconds).stringFromTimeInterval()
        } catch {
            print("Error loading duration for \(fileURL): \(error)")
            return "00:00"
        }
    }

    /// Extract metadata from a media file
    static func extractSongMetadata(from fileURL: URL) async -> [String: Any] {
        var dict: [String: Any] = [:]
        let asset = AVAsset(url: fileURL)
        do {
            // Load all metadata items asynchronously
            let items: [AVMetadataItem] = try await asset.load(.metadata)
            for item in items {
                // Load the item's value
                if let key = item.commonKey?.rawValue ?? (item.key as? String),
                   let value = try await item.load(.value) {
                    dict[key] = value
                }
            }
        } catch {
            print("Error loading metadata for \(fileURL): \(error)")
        }
        return dict
    }

    // MARK: - Image Handling
    
    /// Get the file URL for images stored in the `images` directory
    static func getImageFileURL(for fileName: String) -> URL {
        return getMetadataFileURL(for: "images/\(fileName)")
    }

    /// Save an image to the `images` directory, ensuring the directory exists. Returns the saved file URL.
    @discardableResult
    static func saveImage(_ image: UIImage, withName name: String) -> URL? {
        // Ensure images directory exists
        ensureImagesDirectoryExists()
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let fileURL = getImageFileURL(for: "\(name).jpg")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    /// Deletes an image from the `images` directory by filename.
    /// - Parameter fileName: The image’s filename (e.g. "abc123.jpg").
    /// - Returns: True if deletion succeeded, false otherwise.
    @discardableResult
    static func deleteImage(named fileName: String?) -> Bool {
        // Ensure we have a valid filename
        guard let name = fileName, !name.isEmpty else { return false }
        // Build the URL in the images directory
        let url = getImageFileURL(for: name)
        // Delete and return the result
        return deleteFile(at: url)
    }

    /// Ensure the `images` directory exists, creating it if necessary.
    static func ensureImagesDirectoryExists() {
        let imagesDir = getMetadataFileURL(for: "images")
        let fm = FileManager.default
        if !fm.fileExists(atPath: imagesDir.path) {
            do {
                try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating images directory: \(error)")
            }
        }
    }

    // MARK: - Songs Handling

    /// Returns the URL to the `Documents/Songs` directory, creating it if necessary.
    @discardableResult
    static func getSongsDirectoryURL() -> URL {
        let songsDir = getMetadataFileURL(for: "Songs")
        let fm = FileManager.default
        if !fm.fileExists(atPath: songsDir.path) {
            do {
                try fm.createDirectory(at: songsDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Songs directory: \(error)")
            }
        }
        return songsDir
    }

    /// Builds a file URL inside the `Documents/Songs` directory for the given filename.
    static func getSongFileURL(for fileName: String) -> URL {
        return getSongsDirectoryURL().appendingPathComponent(fileName)
    }

    /// Copies an external media file into `Documents/Songs` and returns the new URL.
    static func copySongFile(from sourceURL: URL, named destFileName: String) -> URL? {
        let destinationURL = getSongFileURL(for: destFileName)
        let fm = FileManager.default
        // Remove existing file if present
        try? fm.removeItem(at: destinationURL)
        do {
            try fm.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to copy song file to Songs directory: \(error)")
            return nil
        }
    }
    
    /// Deletes a copied song file from Documents/Songs by its filename (e.g. "abc123.mp3").
    @discardableResult
    static func deleteSongFile(named fileName: String?) -> Bool {
        guard let name = fileName, !name.isEmpty else { return false }
        let url = getSongFileURL(for: name)
        return deleteFile(at: url)
    }

}
