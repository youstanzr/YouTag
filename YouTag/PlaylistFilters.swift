//
//  PlaylistFilters.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/25/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import Foundation

struct PlaylistFilters {
	
	enum FilterType: String {
		case tags = "tags"
		case artists = "artists"
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
		let result = NSMutableArray()
		
		return result
	}
	
	mutating func addUniqueFilter(_ filters: NSMutableArray, type: FilterType) {
		if [FilterType.tags, FilterType.artists, FilterType.album, FilterType.releaseYear].contains(type) {	// if type was equal to one of those types
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
		if type == FilterType.tags {
			resultArr = tags
		} else if type == FilterType.artists {
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
		
		if type == FilterType.tags {
			tags = resultArr
		} else if type == FilterType.artists {
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
