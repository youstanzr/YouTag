//
//  LibraryManager.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import Foundation

class LibraryManager {
	var libraryArray: NSMutableArray!

    init() {
        self.refreshLibraryArray()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func refreshLibraryArray() {
		libraryArray = NSMutableArray(array: UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray())
	}

	static func getLibraryArray() -> NSMutableArray {
		return NSMutableArray(array: UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray())
	}
	
    func addSongToLibrary(songTitle: String, videoUrl: URL, thumbnailUrl: URL, duration: String, songID: String) -> Bool {
        if self.checkSongExistInLibrary(songID: songID) {
            return false
        } else {
			let songDict = ["songTitle": songTitle, "artistName": "", "songID": songID, "duration": duration, "songTags": NSMutableArray()] as [String : Any]
			libraryArray.add(songDict)
			UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")

            LocalFilesManager.saveSongThumbnail(thumbnailURL: thumbnailUrl, filename: songID)
            LocalFilesManager.saveVideoToFile(videoURL: videoUrl, filename: songID)
            LocalFilesManager.extractAudioFromVideo(songID: songID)
            _ = LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).mp4")
            self.refreshLibraryArray()
            return true
        }
    }
    
	func deleteSongFromLibrary(songID: String) {
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			if songDict["songID"] as! String == songID {
				if LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).m4a") &&
					LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).jpg"){
					libraryArray.remove(songDict)
				}
				break
			}
		}
		UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
	}

	func checkSongExistInLibrary(songID: String) -> Bool {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			if songDict["songID"] as! String == songID {
				return true
			}
		}
		return false
	}

	func getSong(forID songID: String) -> Dictionary<String, Any> {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			if songDict["songID"] as! String == songID {
				return songDict
			}
		}
		return Dictionary()
	}

    func updateSong(newSong: Dictionary<String, Any>) {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, AnyObject>
			if songDict["songID"] as! String == newSong["songID"] as! String {
				libraryArray.replaceObject(at: i, with: newSong)
				UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
				break
			}
		}
    }
	
	static func getAllTags() -> NSMutableArray {
		let tagsList = NSMutableArray()
		let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
		var songDict = Dictionary<String, Any>()
		var songTags = NSMutableArray()
		for i in 0 ..< songArr.count {
			songDict = songArr.object(at: i) as! Dictionary<String, AnyObject>
			songTags = NSMutableArray(array: songDict["songTags"] as? NSArray ?? NSArray())
			for j in 0 ..< songTags.count {
				if !tagsList.contains(songTags[j]) {
					tagsList.add(songTags[j])
				}
			}
		}
		return tagsList
	}
}
