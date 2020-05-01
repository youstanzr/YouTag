//
//  LocalFilesManager.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/1/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import AVFoundation

class LocalFilesManager {
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	static func getLocalFileURL(withNameAndExtension fileName_ext: String) -> URL {
		return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName_ext)
	}
	
	static func getLocalFileSize(fileName_ext: String) -> String {
		do {
			let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
			let documentsDirectory = paths[0]
			let dataPathStr = documentsDirectory + "/\(fileName_ext)"
			let attr = try FileManager.default.attributesOfItem(atPath: dataPathStr)
			let fileSize = attr[FileAttributeKey.size] as! UInt64
			return ByteCountFormatter().string(fromByteCount: Int64(bitPattern: fileSize))
		} catch {
			print("Error: \(error.localizedDescription)")
			return ""
		}
	}
	
	static func saveVideoToFile(videoURL: URL, filename: String) {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory = paths[0]
		let dataPathStr = documentsDirectory + "/" + filename + ".mp4"
		let dataPath = URL(fileURLWithPath: dataPathStr)
		let videoData = NSData(contentsOf: videoURL as URL)
		do {
			try videoData?.write(to: dataPath)
			print("Saved video: \(dataPath)")
		} catch {
			print(error.localizedDescription)
		}
	}
	
	static func extractAudioFromVideo(songID: String) {
		let in_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(songID).mp4")
		let out_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(songID).m4a")
		let asset = AVURLAsset(url: in_url)
		
		asset.writeAudioTrack(to: out_url, success: {
			print("Converted video-mp4 to audio-m4a: \(out_url.absoluteString)")
		}) { (error) in
			print(error.localizedDescription)
		}
	}
	
	static func saveSongThumbnail(thumbnailURL: URL, filename: String) {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory = paths[0]
		let dataPathStr = documentsDirectory + "/" + filename + ".jpg"
		let dataPath = URL(fileURLWithPath: dataPathStr)
		let imageData = try? Data(contentsOf: thumbnailURL as URL)
		do {
			try imageData?.write(to: dataPath)
			print("Saved thumbnail: \(dataPath)")
		} catch {
			print(error.localizedDescription)
		}
	}
	
	static func saveImage(_ image: UIImage, withName filename: String) {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory = paths[0]
		let dataPathStr = documentsDirectory + "/" + filename + ".jpg"
		
		let dataPath = URL(fileURLWithPath: dataPathStr)
		do {
			try image.jpegData(compressionQuality: 1.0)?.write(to: dataPath, options: .atomic)
		} catch {
			print("file cant not be save at path \(dataPath), with error : \(error)");
		}
	}

	static func deleteFile(withNameAndExtension filename_ext: String) -> Bool{
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory = paths[0]
		let dataPathStr = documentsDirectory + "/" + filename_ext
		if FileManager.default.fileExists(atPath: dataPathStr) {
			do {
				try FileManager.default.removeItem(atPath: dataPathStr)
				print("Removed file: \(dataPathStr)")
			} catch let removeError {
				print("couldn't remove file at path", removeError.localizedDescription)
				return false
			}
		}
		return true
	}
	
}
