//
//  Song.swift
//  YouTag
//
//  Created by Youstanzr on 3/14/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation

struct Song : Codable{

	var title: String
	var artist: String
	var id: String
	var duration: String
	var tags: [String]
	
	init() {
		title = ""
		artist = ""
		id = ""
		duration = ""
		tags = []
	}
	
	init(title: String, artist: String, id: String, duration: String, tags: [String]) {
		self.title = title
		self.artist = artist
		self.id = id
		self.duration = duration
		self.tags = tags
	}
	
}
