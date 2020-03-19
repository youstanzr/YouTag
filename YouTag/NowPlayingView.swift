//
//  NowPlayingView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/13/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//
import UIKit

class NowPlayingView: UIView {
	var audioPlayer: YTAudioPlayer!
	var songDict = Dictionary<String, Any>()
	let thumbnailImageView = UIImageView()
	let titleLabel: UILabel = {
		let lbl = UILabel()
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22)
		lbl.textAlignment = .left
		return lbl
	}()
	let artistLabel: UILabel = {
		let lbl = UILabel()
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
		lbl.textAlignment = .left
		return lbl
	}()
	let previousButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "Previous_Image"), for: UIControl.State.normal)
		return btn
	}()
	let pausePlayButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "Play_Image"), for: UIControl.State.normal)
		return btn
	}()
	let nextButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "Next_Image"), for: UIControl.State.normal)
		return btn
	}()
	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
		super.init(frame: frame)
		audioPlayer = YTAudioPlayer(nowPlayingView: self)
		
		self.addSubview(thumbnailImageView)
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
		thumbnailImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		thumbnailImageView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -15).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1.25).isActive = true

		thumbnailImageView.layer.cornerRadius = 5.0
        thumbnailImageView.layer.borderWidth = 1.0
        thumbnailImageView.layer.borderColor = UIColor.lightGray.cgColor
        
		nextButton.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
		self.addSubview(nextButton)
		nextButton.translatesAutoresizingMaskIntoConstraints = false
		nextButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
		nextButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		nextButton.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3).isActive = true
		nextButton.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3).isActive = true

		pausePlayButton.addTarget(self, action: #selector(pausePlayButtonAction), for: .touchUpInside)
		self.addSubview(pausePlayButton)
		pausePlayButton.translatesAutoresizingMaskIntoConstraints = false
		pausePlayButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -5).isActive = true
		pausePlayButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
		pausePlayButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true
		pausePlayButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true

		previousButton.addTarget(self, action: #selector(previousButtonAction), for: .touchUpInside)
		self.addSubview(previousButton)
		previousButton.translatesAutoresizingMaskIntoConstraints = false
		previousButton.trailingAnchor.constraint(equalTo: pausePlayButton.leadingAnchor, constant: -5).isActive = true
		previousButton.centerYAnchor.constraint(equalTo: pausePlayButton.centerYAnchor).isActive = true
		previousButton.heightAnchor.constraint(equalTo: pausePlayButton.heightAnchor).isActive = true
		previousButton.widthAnchor.constraint(equalTo: pausePlayButton.heightAnchor).isActive = true

        self.addSubview(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10).isActive = true
		titleLabel.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: -5).isActive = true
		titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 5).isActive = true
		titleLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.5, constant: -5).isActive = true

        self.addSubview(artistLabel)
		artistLabel.translatesAutoresizingMaskIntoConstraints = false
		artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
		artistLabel.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: -5).isActive = true
		artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
		artistLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor).isActive = true
	}
	
	func updateSongDict(to newSongDict: Dictionary<String, Any>) {
		self.songDict = newSongDict
		self.refreshView()
	}
	
	func refreshView() {
		let songID = songDict["songID"] as? String ?? ""
		self.titleLabel.text = songDict["songTitle"] as? String
		self.artistLabel.text = songDict["artistName"] as? String
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songID).jpg"))
		self.thumbnailImageView.image = UIImage(data: imageData ?? Data())
		
		let currentController = self.getCurrentViewController() as? ViewController
		if let c = currentController?.nowPlayingLibraryView.playlistArray {
			_ = audioPlayer.setupPlayer(withPlaylist: c)
		} else {
			_ = audioPlayer.setupPlayer(withSong: songDict)
		}
		self.refreshPausePlayButton()
	}
	
	func refreshPausePlayButton() {
		if self.audioPlayer.isPlaying() {
			self.pausePlayButton.setImage(UIImage(named: "Pause_Image"), for: UIControl.State.normal)
		} else {
			self.pausePlayButton.setImage(UIImage(named: "Play_Image"), for: UIControl.State.normal)
		}
	}

    @objc func pausePlayButtonAction(sender: UIButton?) {
		if self.audioPlayer.isPlaying() {
			print("Paused")
			audioPlayer.pause()
		}else{
			print("Playing")
			audioPlayer.play()
		}
    }
	
    @objc func nextButtonAction(sender: UIButton!) {
        print("Next Button tapped")
		audioPlayer.next()
    }
    
    @objc func previousButtonAction(sender: UIButton!) {
        print("Previous Button tapped")
		audioPlayer.prev()
    }
}
