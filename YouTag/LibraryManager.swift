//
//  LibraryManager.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class LibraryManager {

	enum SongProperties: String {
		case id = "id"
		case link = "link"
		case fileExtension = "fileExtension"
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
	
	/*
	If the following parameters have no value then pass nil and the function will handle it
		Song ID -> will generate a custom id
		Song Title -> will be set to Song ID
		Thumbnail URL -> It will skip downloading a thumbnail image
	*/
	func addSongToLibrary(songTitle: String?, songUrl: URL, songExtension: String , thumbnailUrl: URL?, songID: String?, completion: (() -> Void)? = nil) {
		let sID = songID == nil ? "dl_" + generateIDFromTimeStamp() : "yt_" + songID! + generateIDFromTimeStamp()
		var newExtension: String
		
		let currentViewController = UIApplication.getCurrentViewController()
		currentViewController?.showProgressView(onView: (currentViewController?.view)!, withTitle: "Downloading...")

		let dispatchGroup = DispatchGroup()  // To keep track of the async download group
		print("Starting the required downloads for song")
		dispatchGroup.enter()
		if songExtension == "mp4" {
			LocalFilesManager.downloadFile(from: songUrl, filename: sID, extension: songExtension, completion: {
				LocalFilesManager.extractAudioFromVideo(songID: sID, completion: { error in
					if error == nil {  // Successful extracting audio from video
						_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).\(songExtension)")
					} else {  // Error extracting audio from video
						_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).mp4")  // Delete the downloaded video
						dispatchGroup.leave()
						return
					}
					dispatchGroup.leave()
				})
			})
			newExtension = "m4a"
		} else {
			LocalFilesManager.downloadFile(from: songUrl, filename: sID, extension: songExtension, completion: {
				dispatchGroup.leave()
			})
			newExtension = songExtension
		}
		
		if let imageUrl = thumbnailUrl {
			dispatchGroup.enter()
			LocalFilesManager.downloadFile(from: imageUrl, filename: sID, extension: "jpg", completion: {
				dispatchGroup.leave()
			})
		}
		
		dispatchGroup.notify(queue: DispatchQueue.main) {  // All async download in the group completed
			print("All async download in the group completed")
			currentViewController?.removeProgressView()
			if let artworkImage = LocalFilesManager.extractArtworkFromSongMetadata(songID: sID, songExtension: newExtension) {
				LocalFilesManager.saveImage(artworkImage, withName: sID)
			}
			let duration = LocalFilesManager.extractDurationForSong(songID: sID, songExtension: newExtension)
			let link = songID == nil ? songUrl.absoluteString : "https://www.youtube.com/embed/\(songID ?? "UNKNOWN_ERROR")"
			let songDict = ["id": sID, "title": songTitle ?? sID, "artists": NSMutableArray(), "album": "",
							"releaseYear": "", "duration": duration, "lyrics": "", "tags": NSMutableArray(),
							"link": link, "fileExtension": newExtension] as [String : Any]
			self.libraryArray.add(songDict)
			UserDefaults.standard.set(self.libraryArray, forKey: "LibraryArray")
			self.refreshLibraryArray()
			completion?()
		}
    }
    
	func deleteSongFromLibrary(songID: String) {
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["id"] as! String == songID {
				let songExt = (songDict["fileExtension"] as? String) ?? "m4a"  //support legacy code
				if LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).\(songExt)") {
					_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).jpg")
					libraryArray.remove(songDict)
				}
				break
			}
		}
		UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
	}

	func checkSongExistInLibrary(songLink: String) -> Bool {
		self.refreshLibraryArray()
		var songDict = Dictionary<String, Any>()
		for i in 0 ..< libraryArray.count {
			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
			if songDict["link"] as! String == songLink {
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
	
	private func generateIDFromTimeStamp() -> String {
		let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		var timestamp: Int = Int(Date().timeIntervalSince1970 * 1000)
		var str = ""
		while timestamp != 0 {
			str += letters[timestamp%10]
			timestamp /= 10
		}
		return str
	}

}
