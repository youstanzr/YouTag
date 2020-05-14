//
//  LibraryManager.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

typealias MetadataMap = Dictionary<String, Any>

class LibraryManager {
    
	enum ValueType {
		case min
		case max
	}
	var libraryArray: [Song] = []

	
    init() {
        self.refreshLibraryArray()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func refreshLibraryArray() {
        libraryArray = LibraryManager.fetchAllSongs()
	}

	static func getLibraryArray() -> [Song] {
		return fetchAllSongs()
	}
	
	/*
	If the following parameters have no value then pass nil and the function will handle it
		Song ID -> will generate a custom id
		Song Title -> will be set to Song ID
		Thumbnail URL -> It will skip downloading a thumbnail image
	*/
	func addSongToLibrary(songTitle: String?,
                          songUrl: URL,
                          songExtension: String,
                          thumbnailUrl: URL?,
                          songID: String?,
                          completion: (() -> Void)? = nil) {
		let sID = songID == nil ? "dl_" + generateIDFromTimeStamp() : "yt_" + songID! + generateIDFromTimeStamp()
		var newExtension: String
		var errorStr: String?
		
		let currentViewController = UIApplication.getCurrentViewController()
		currentViewController?.showProgressView(onView: (currentViewController?.view)!, withTitle: "Downloading...")

		let dispatchGroup = DispatchGroup()  // To keep track of the async download group
		print("Starting the required downloads for song")
		dispatchGroup.enter()
		if songExtension == "mp4" {
			LocalFilesManager.downloadFile(from: songUrl, filename: sID, extension: songExtension, completion: { error in
				if error == nil  {
					LocalFilesManager.extractAudioFromVideo(songID: sID, completion: { error in
						_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).mp4")  // Delete the downloaded video
						dispatchGroup.leave()
						if error != nil {  // Failed to extract audio from video
							_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).m4a")  // Delete the extracted audio if available
							errorStr = error!.localizedDescription
						}
					})
				} else {
					_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).mp4")  // Delete the downloaded video if available
					print("Error downloading video: " + error!.localizedDescription)
					dispatchGroup.leave()
					errorStr = error!.localizedDescription
				}
			})
			newExtension = "m4a"
		} else {
			LocalFilesManager.downloadFile(from: songUrl, filename: sID, extension: songExtension, completion: { error in
				dispatchGroup.leave()
				if error != nil  {
					_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(sID).\(songExtension)")  // Delete the downloaded video if available
					print("Error downloading song: " + error!.localizedDescription)
					errorStr = error!.localizedDescription
				}
			})
			newExtension = songExtension
		}
		
		if let imageUrl = thumbnailUrl {
			dispatchGroup.enter()
			LocalFilesManager.downloadFile(from: imageUrl, filename: sID, extension: "jpg", completion: { error in
				dispatchGroup.leave()
				if error != nil  {
					print("Error downloading thumbnail: " + error!.localizedDescription)
				}
			})
		}
		
		dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in  // All async download in the group completed
            guard let self = self else { return }
			currentViewController?.removeProgressView()
            print("All async download in the group completed")
            
            guard errorStr == nil else {
                let alert = UIAlertController(title: "Error", message: errorStr, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
                currentViewController?.present(alert, animated: true, completion: nil)
                return
            }
            
            
            let duration = LocalFilesManager.extractDurationForSong(songID: sID, songExtension: newExtension)
            let link = songID == nil ? songUrl.absoluteString : "https://www.youtube.com/embed/\(songID ?? "UNKNOWN_ERROR")"
            
            var song = Song(id: sID,
                            title: songTitle ?? sID,
                            link: link,
                            duration: duration,
                            fileExt: newExtension)

            // Parse metadata and enrich our song based on those values
            let metadataDict = LocalFilesManager.extractSongMetadata(songID: sID, songExtension: newExtension)
            LibraryManager.enrichSong(&song, fromMetadataDict: metadataDict)
            
            self.libraryArray.append(song)
            UserDefaults.standard.set(self.libraryArray, forKey: "LibraryArray")
            self.refreshLibraryArray()
            completion?()
			
		}
    }
	
	static func enrichSong(_ song: inout Song,
                        fromMetadataDict mdDict: MetadataMap){
        var enrichedSong = song
        
        for (key, value) in mdDict {
            // Ignore values whose are strings and empty
            if let value = value as? String, value.isEmpty {
                continue
            }
            // Same but for data
            if let value = value as? Data, value.isEmpty {
                continue
            }
            
            guard let localKey = try? MetadataExtractor.parseToSupported(from: key) else {
                #if DEBUG
                    print("ignoring: \(key)")
                #endif
                break
            }
            
            switch localKey {
            case .artist:
                guard let value = value as? String else {
                    continue
                }
                enrichedSong.artists.append(value)
                break
            case .title:
                guard enrichedSong.title == enrichedSong.id || enrichedSong.title.isEmpty else {
                    continue
                }
                enrichedSong.title = value as? String ?? ""
            case .album:
                enrichedSong.album = value as? String ?? ""
                break
            case .year:
                enrichedSong.releaseYear = value as? String ?? ""
            case .tags:
                enrichedSong.tags.append(value as? String ?? "")
            case .artwork:
                guard let data = value as? Data else { continue }
                guard !LocalFilesManager.checkFileExist(enrichedSong.id + ".jpg") else {
                    continue
                }
                // make sure image is jpg
                guard let jpgImageData = UIImage(data: data)?.jpegData(compressionQuality: 1) else {
                    continue
                }
                LocalFilesManager.saveImage(UIImage(data: jpgImageData), withName: enrichedSong.id)
            default:
                #if DEBUG
                    print("not supported key found")
                #endif
            }
        }
        song = enrichedSong
	}
    
	func deleteSongFromLibrary(songID: String) {
//		var songDict = Dictionary<String, Any>()
//		for i in 0 ..< libraryArray.count {
//			songDict = libraryArray.object(at: i) as! Dictionary<String, Any>
//			if songDict["id"] as! String == songID {
//				let songExt = (songDict["fileExtension"] as? String) ?? "m4a"  //support legacy code
//				if LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).\(songExt)") {
//					_ = LocalFilesManager.deleteFile(withNameAndExtension: "\(songID).jpg")
//					libraryArray.remove(songDict)
//				}
//				break
//			}
//		}
        for (index, song) in libraryArray.enumerated() {
            guard song.id == songID else {
                return
            }
            guard LocalFilesManager.deleteFile(withNameAndExtension: "\(song.id).\(song.fileExt)") else {
                return
            }
            libraryArray.remove(at: index)
            break
        }
		UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
	}

	func checkSongExistInLibrary(songLink: String) -> Bool {
		self.refreshLibraryArray()

        return libraryArray.contains(where: { $0.link == songLink } )
	}

	func getSong(forID songID: String) -> Song? {
		self.refreshLibraryArray()
        return libraryArray.first(where: { $0.id == songID })
	}

    func updateSong(newSong: Song) {
		self.refreshLibraryArray()
        guard let cachedSongIndex = libraryArray.firstIndex(where: { $0.id == newSong.id }) else {
            return
        }
        libraryArray[cachedSongIndex] = newSong
        UserDefaults.standard.set(libraryArray, forKey: "LibraryArray")
    }
    
    private static func retriveByCacheKey(_ key: MetadataExtractor.LocalSupportedMetadata,
                                          properties: [String: Any]) -> String? {
        return properties[key.cacheKey] as? String
    }
    
    private static func fetchAllSongs() -> [Song] {
        let rawSongs = UserDefaults.standard.value(forKey: "LibraryArray") as? NSArray ?? NSArray()
        var songs: [Song] = []
        
        for rawSong in rawSongs {
            let properties = rawSong as! Dictionary<String, Any>

            guard let id = retriveByCacheKey(.id, properties: properties) else {
                continue
            }
            
            guard let title = retriveByCacheKey(.title, properties: properties) else {
                continue
            }
            
            guard let link = retriveByCacheKey(.link, properties: properties) else {
                continue
            }
            
            guard let duration = retriveByCacheKey(.duration, properties: properties) else {
                continue
            }
            
            guard let fileExt = retriveByCacheKey(.fileExtension, properties: properties) else {
                continue
            }
            
            
            var localSong = Song(id: id, title: title, link: link, duration: duration, fileExt: fileExt)
            enrichSong(&localSong, fromMetadataDict: properties)
            songs.append(localSong)
        }
        
        return songs
    }
	
    // Filters for songs?
    static func getAll(_ type: MetadataExtractor.LocalSupportedMetadata) -> NSMutableArray {
        var list: [String] = []
        
        let songs = fetchAllSongs()
        
        switch type {
        case .id:
            let ids = songs.map { $0.id }
            ids.forEach { list.append($0) }
        case .artist:
            let artists = songs.flatMap { $0.artists }
            for artist in artists {
                list.append(artist)
            }
        case .title:
            list.append(contentsOf: songs.map { $0.title })
        case .album:
            let albums = songs.map { $0.album ?? "" }
            list.append(contentsOf: albums)
        case .year:
            let years = songs.map { $0.releaseYear }
            years.forEach { list.append($0) }
        case .tags:
            // cast to nsarray
            let tags = songs.flatMap { $0.tags }
            for tag in tags {
                list.append(tag)
            }
        case .fileExtension:
            let fileExts = songs.map { $0.fileExt }
            fileExts.forEach { list.append($0) }
        default:
            #if DEBUG
                print("not implemeneted \(type)")
            #endif
            break
        }
        
        let filteredList = list.filter { !$0.isEmpty }
        let nsList = NSMutableArray()
        
        filteredList.forEach { nsList.add($0) }
        
        return nsList.sortAscending()
	}
	
	static func getDuration(_ durType: ValueType) -> Double {
        // need to test this
        if durType == .min {
            let songs = fetchAllSongs()
            var min: TimeInterval = TimeInterval.infinity
            
            for song in songs {
                let duration = song.duration.convertToTimeInterval()
                guard duration < min else {
                    continue
                }
                min = duration
            }
            return min == TimeInterval.infinity ? 0 : min
        } else if durType == .max {
            let songs = fetchAllSongs()
            var max: TimeInterval = 0
            
            for song in songs {
                let duration = song.duration.convertToTimeInterval()
                guard duration > max else {
                    continue
                }
                max = duration
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
