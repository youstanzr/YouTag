//
//  LibraryManager.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import Foundation

class LibraryManager {

	enum SongProperties: String {
		case id = "id"
		case title = "title"
		case artists = "artists"
		case album = "album"
		case releaseYear = "releaseYear"
		case duration = "duration"
		case lyrics = "lyrics"
		case tags = "tags"
	}
	enum ValueType {
		case min
		case max
	}
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
			let songDict = ["id": songID, "title": songTitle, "artists": NSMutableArray(), "album": "",
							"releaseYear": "", "duration": duration, "lyrics": "", "tags": NSMutableArray()] as [String : Any]
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
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["id"] as! String == songID {
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
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["id"] as! String == songID {
				return true
			}
		}
		return false
	}

	func getSong(forID songID: String) -> Dictionary<String, Any> {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["id"] as! String == songID {
				return songDict
			}
		}
		return Dictionary()
	}

    func updateSong(newSong: Dictionary<String, Any>) {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["id"] as! String == newSong["id"] as! String {
				libraryArray.replaceObject(at: i, with: newSong)
				UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
				break
			}
		}
    }
	
	static func getAll(_ type: SongProperties) -> NSMutableArray {
		let list = NSMutableArray()
		let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
		var songDict = Dictionary<String, Any>()
		var songArrProperty = NSMutableArray()
		var songStrProperty = String()
		for i in 0 ..< songArr.count {
			songDict = songArr.object(at: i) as! Dictionary<String, Any>
			if type == .artists || type == .tags {
				songArrProperty = NSMutableArray(array: songDict[type.rawValue] as? NSArray ?? NSArray())
				for j in 0 ..< songArrProperty.count {
					if !list.contains(songArrProperty[j]) && (songArrProperty[j] as? String ?? "") != "" {
						list.add(songArrProperty[j])
					}
				}
			} else {
				songStrProperty = songDict[type.rawValue] as? String ?? ""
				if !list.contains(songStrProperty) && songStrProperty != "" {
					list.add(songStrProperty)
				}
			}
		}
		return list
	}
	
	static func getDuration(_ durType: ValueType) -> Double {
		if durType == .min {
			let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
			var songDict = Dictionary<String, Any>()
			var min: TimeInterval = TimeInterval.infinity
			for i in 0 ..< songArr.count {
				songDict = songArr.object(at: i) as! Dictionary<String, Any>
				if (songDict["duration"] as! String).convertToTimeInterval() < min {
					min = (songDict["duration"] as! String).convertToTimeInterval()
				}
			}
			return min == TimeInterval.infinity ? 0 : min
		} else if durType == .max {
			let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
			var songDict = Dictionary<String, Any>()
			var max: TimeInterval = 0
			for i in 0 ..< songArr.count {
				songDict = songArr.object(at: i) as! Dictionary<String, Any>
				if (songDict["duration"] as! String).convertToTimeInterval() > max {
					max = (songDict["duration"] as! String).convertToTimeInterval()
				}
			}
			return max
		}
		return 0
	}
	
	static func getReleaseYear(_ durType: ValueType) -> Int {
		if durType == .min {
			let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
			var songDict = Dictionary<String, Any>()
			var min: Int = Int.max
			for i in 0 ..< songArr.count {
				songDict = songArr.object(at: i) as! Dictionary<String, Any>
				if Int(songDict["releaseYear"] as? String ?? "") ?? Int.max < min {
					min = Int(songDict["releaseYear"] as? String ?? "") ?? Int.max
				}
			}
			return min == Int.max ? 0 : min
		} else if durType == .max {
			let songArr = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
			var songDict = Dictionary<String, Any>()
			var max: Int = 0
			for i in 0 ..< songArr.count {
				songDict = songArr.object(at: i) as! Dictionary<String, Any>
				if Int(songDict["releaseYear"] as? String ?? "") ?? 0 > max {
					max = Int(songDict["releaseYear"] as? String ?? "") ?? 0
				}
			}
			return max
		}
		return 0
	}
	
}
