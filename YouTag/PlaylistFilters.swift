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
		case artist = "artists"
		case album = "album"
		case releaseYearRange = "releaseYearRange"
		case releaseYear = "releaseYear"
		case duration = "duration"
	}
	var tags: NSMutableArray
	var artists: NSMutableArray
	var album: NSMutableArray
	var releaseYearRange: NSMutableArray
	var releaseYear: NSMutableArray
	var duration: NSMutableArray
	
	func getFilters() -> NSMutableArray {
		let resultArr = NSMutableArray()
		var tempDuration: [TimeInterval]
		var tempArr: NSMutableArray
		for i in 0 ..< tags.count {
			resultArr.add(NSMutableArray(objects: "tags", tags.object(at: i)))
		}
		for i in 0 ..< artists.count {
			resultArr.add(NSMutableArray(objects: "artists", artists.object(at: i)))
		}
		for i in 0 ..< album.count {
			resultArr.add(NSMutableArray(objects: "album", album.object(at: i)))
		}
		for i in 0 ..< releaseYearRange.count {
			tempArr = releaseYearRange.object(at: i) as! NSMutableArray
			resultArr.add(NSMutableArray(objects: "releaseYearRange", "\(tempArr.object(at: 0)) - \(tempArr.object(at: 1))"))
		}
		for i in 0 ..< releaseYear.count {
			resultArr.add(NSMutableArray(objects: "releaseYear", releaseYear.object(at: i)))
		}
		for i in 0 ..< duration.count {
			tempDuration = (duration.object(at: i) as! NSMutableArray) as! [TimeInterval]
			tempArr = NSMutableArray(array: tempDuration.map{ ($0 as TimeInterval).stringFromTimeInterval() })
			resultArr.add(NSMutableArray(objects: "duration", "\(tempArr.object(at: 0)) - \(tempArr.object(at: 1))"))
		}
		return resultArr
	}
	
	mutating func deleteFilter(using arr: NSMutableArray) {
		var tuple: NSMutableArray
		var temp: [String]
		var tempArr: NSMutableArray
		for i in 0 ..< arr.count {
			tuple = arr.object(at: i) as! NSMutableArray
			if tuple.object(at: 0) as! String == "tags" {
				tags.remove(tuple.object(at: 1) as! String)
			} else if tuple.object(at: 0) as! String == "artists" {
				artists.remove(tuple.object(at: 1) as! String)
			} else if tuple.object(at: 0) as! String == "album" {
				album.remove(tuple.object(at: 1) as! String)
			} else if tuple.object(at: 0) as! String == "releaseYearRange" {
				temp = ((tuple.object(at: 1) as! String).components(separatedBy: " - "))
				tempArr = NSMutableArray(array: temp.map{ Int($0)! })
				releaseYearRange.remove(tempArr)
			} else if tuple.object(at: 0) as! String == "releaseYear" {
				releaseYear.remove(tuple.object(at: 1) as! String)
			} else if tuple.object(at: 0) as! String == "duration" {
				temp = ((tuple.object(at: 1) as! String).components(separatedBy: " - "))
				tempArr = NSMutableArray(array: temp.map{ ($0 as String).convertToTimeInterval() })
				duration.remove(tempArr)
			}
		}
	}
	
	mutating func addUniqueFilter(_ filters: NSMutableArray, type: FilterType) {
		if [FilterType.tag, FilterType.artist, FilterType.album, FilterType.releaseYear].contains(type) {	// if type was equal to one of those types
			addStringFilter(filters, type: type)
		} else if type == FilterType.releaseYearRange {
			addReleaseYrRangeFilter(filters)
		} else if type == FilterType.duration {
			addDurationFilter(filters)
		} else {
			return
		}
	}
	
	mutating fileprivate func addStringFilter (_ filters: NSMutableArray, type: FilterType) {
		var resultArr: NSMutableArray
		if type == FilterType.tag {
			resultArr = tags
		} else if type == FilterType.artist {
			resultArr = artists
		} else if type == FilterType.album {
			resultArr = album
		} else if type == FilterType.releaseYear {
			resultArr = releaseYear
		} else {
			resultArr = NSMutableArray()
		}
		
		var i = 0
		while i < filters.count {
			if !resultArr.contains(filters.object(at: i) as! String) {
				resultArr.add(filters.object(at: i) as! String)
			}
			i += 1
		}
		
		if type == FilterType.tag {
			tags = resultArr
		} else if type == FilterType.artist {
			artists = resultArr
		} else if type == FilterType.album {
			album = resultArr
		} else if type == FilterType.releaseYear {
			releaseYear = resultArr
		}
	}
	
	mutating fileprivate func addReleaseYrRangeFilter (_ filters: NSMutableArray) {
		// array of Int array: [lower value, upper value]
		let tempObj = NSMutableArray(objects: filters.object(at: 0) as! Int, filters.object(at: 1) as! Int)
		if !releaseYearRange.contains(tempObj) {
			releaseYearRange.add(tempObj)
		}
	}

	mutating fileprivate func addDurationFilter (_ filters: NSMutableArray) {
		// array of TimeInterval array: [lower value, upper value]
		let tempObj = NSMutableArray(objects: filters.object(at: 0) as! TimeInterval, filters.object(at: 1) as! TimeInterval)
		if !duration.contains(tempObj) {
			duration.add(tempObj)
		}
	}

}
