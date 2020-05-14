//
//  NowPlayingView.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 8/13/19.
//  Copyright © 2019 Youstanzr Alqattan. All rights reserved.
//
import UIKit
import MarqueeLabel

protocol NowPlayingViewDelegate: class {
	func shufflePlaylist()
}

class NowPlayingView: UIView, YYTAudioPlayerDelegate {

	weak var NPDelegate: NowPlayingViewDelegate?

	var audioPlayer: YYTAudioPlayer!
	var songID = ""
	let thumbnailImageView: UIImageView = {
		let imgView = UIImageView()
		imgView.layer.cornerRadius = 5.0
		imgView.layer.borderWidth = 1.0
		imgView.layer.borderColor = UIColor.lightGray.cgColor
		imgView.layer.masksToBounds = true
		return imgView
	}()
	let titleLabel: MarqueeLabel = {
		let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
		lbl.trailingBuffer = 40.0
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22)
		lbl.textAlignment = .left
		return lbl
	}()
	let artistLabel: MarqueeLabel = {
		let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
		lbl.textColor = GraphicColors.gray
		lbl.trailingBuffer = 40.0
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.65)
		lbl.textAlignment = .left
		return lbl
	}()
	let previousButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "previous"), for: UIControl.State.normal)
		return btn
	}()
	let pausePlayButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "play"), for: UIControl.State.normal)
		return btn
	}()
	let nextButton: UIButton = {
		let btn = UIButton()
		btn.setImage(UIImage(named: "next"), for: UIControl.State.normal)
		return btn
	}()
	let songControlView = UIView()
	let progressBar: UISlider = {
		let pBar = UISlider()
		pBar.tintColor = GraphicColors.orange
		return pBar
	}()
	var isProgressBarSliding = false
	let playbackRateButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = GraphicColors.orange
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.55)
		btn.setTitle("x1", for: .normal)
		return btn
	}()
	let currentTimeLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "00:00"
		lbl.textAlignment = .center
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.55)
		return lbl
	}()
	let timeLeftLabel: UILabel = {
		let lbl = UILabel()
		lbl.text = "00:00"
		lbl.textAlignment = .center
		lbl.font = UIFont(name: "DINAlternate-Bold", size: 22 * 0.55)
		return lbl
	}()
	let playlistControlView = UIView()
	let lyricsButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = .clear
		btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 24)
		btn.setTitle("What's next", for: .normal)
		btn.setTitleColor(GraphicColors.orange, for: .normal)
		return btn
	}()
	let lyricsTextView: UITextView = {
		let txtView = UITextView()
		txtView.backgroundColor = .clear
		txtView.textAlignment = .center
		txtView.font = UIFont.init(name: "Optima-BoldItalic", size: 15)
		txtView.isEditable = false
		txtView.layer.borderWidth = 1.0
		txtView.layer.borderColor = GraphicColors.orange.withAlphaComponent(0.5).cgColor
		return txtView
	}()
	let repeatButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = .clear
		btn.imageView!.contentMode = .scaleAspectFit
		btn.setImage(UIImage(named: "loop"), for: UIControl.State.normal)
		btn.alpha = 0.35
		return btn
	}()
	let shuffleButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = .clear
		btn.imageView!.contentMode = .scaleAspectFit
		btn.setImage(UIImage(named: "shuffle"), for: UIControl.State.normal)
		return btn
	}()

	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	init(frame: CGRect, audioPlayer: YYTAudioPlayer) {
		super.init(frame: frame)
		self.audioPlayer = audioPlayer
		self.audioPlayer.delegate = self

		playlistControlView.addBorder(side: .top, color: .lightGray, width: 1.0)
		self.addSubview(playlistControlView)
		playlistControlView.translatesAutoresizingMaskIntoConstraints = false
		playlistControlView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
		playlistControlView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
		playlistControlView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		playlistControlView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.375).isActive = true

		repeatButton.addTarget(self, action: #selector(repeatButtonAction), for: .touchUpInside)
		playlistControlView.addSubview(repeatButton)
		repeatButton.translatesAutoresizingMaskIntoConstraints = false
		repeatButton.leadingAnchor.constraint(equalTo: playlistControlView.leadingAnchor, constant: 2.5).isActive = true
		repeatButton.widthAnchor.constraint(equalTo: playlistControlView.widthAnchor, multiplier: 0.125).isActive = true
		repeatButton.centerYAnchor.constraint(equalTo: playlistControlView.centerYAnchor).isActive = true
		repeatButton.heightAnchor.constraint(equalTo: playlistControlView.heightAnchor).isActive = true
		
		shuffleButton.addTarget(self, action: #selector(shuffleButtonAction), for: .touchUpInside)
		playlistControlView.addSubview(shuffleButton)
		shuffleButton.translatesAutoresizingMaskIntoConstraints = false
		shuffleButton.trailingAnchor.constraint(equalTo: playlistControlView.trailingAnchor, constant: -2.5).isActive = true
		shuffleButton.widthAnchor.constraint(equalTo: playlistControlView.widthAnchor, multiplier: 0.125).isActive = true
		shuffleButton.centerYAnchor.constraint(equalTo: playlistControlView.centerYAnchor).isActive = true
		shuffleButton.heightAnchor.constraint(equalTo: playlistControlView.heightAnchor).isActive = true

		lyricsButton.addTarget(self, action: #selector(lyricsButtonAction), for: .touchUpInside)
		playlistControlView.addSubview(lyricsButton)
		lyricsButton.translatesAutoresizingMaskIntoConstraints = false
		lyricsButton.leadingAnchor.constraint(equalTo: repeatButton.trailingAnchor, constant: 2.5).isActive = true
		lyricsButton.trailingAnchor.constraint(equalTo: shuffleButton.leadingAnchor, constant: -2.5).isActive = true
		lyricsButton.centerYAnchor.constraint(equalTo: playlistControlView.centerYAnchor).isActive = true
		lyricsButton.heightAnchor.constraint(equalTo: playlistControlView.heightAnchor).isActive = true

		let tapOutTextView = UITapGestureRecognizer(target: self, action: #selector(lyricsButtonAction))
		lyricsTextView.addGestureRecognizer(tapOutTextView)
		lyricsTextView.isHidden = true
		self.addSubview(lyricsTextView)
		lyricsTextView.translatesAutoresizingMaskIntoConstraints = false
		lyricsTextView.leadingAnchor.constraint(equalTo: lyricsButton.leadingAnchor).isActive = true
		lyricsTextView.trailingAnchor.constraint(equalTo: lyricsButton.trailingAnchor).isActive = true
		lyricsTextView.topAnchor.constraint(equalTo: lyricsButton.topAnchor).isActive = true
		lyricsTextView.bottomAnchor.constraint(equalTo: lyricsButton.bottomAnchor).isActive = true

		songControlView.addBorder(side: .top, color: .lightGray, width: 1.0)
		self.addSubview(songControlView)
		songControlView.translatesAutoresizingMaskIntoConstraints = false
		songControlView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
		songControlView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
		songControlView.bottomAnchor.constraint(equalTo: playlistControlView.topAnchor).isActive = true
		songControlView.heightAnchor.constraint(equalToConstant: 20).isActive = true

		let thumbImage = makeCircleImage(radius: 15.0, color: .lightGray, borderColor: .clear, borderWidth: 0.0)
		let selectedThumbImage = makeCircleImage(radius: 20.0, color: .lightGray, borderColor: .clear, borderWidth: 0.0)
		progressBar.setThumbImage(thumbImage, for: .normal)
		progressBar.setThumbImage(selectedThumbImage, for: .highlighted)
		progressBar.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
		songControlView.addSubview(progressBar)
		progressBar.translatesAutoresizingMaskIntoConstraints = false
		progressBar.leadingAnchor.constraint(equalTo: songControlView.leadingAnchor, constant: 6.0).isActive = true
		progressBar.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.7, constant: -2.5).isActive = true
		progressBar.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
		progressBar.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
		
		currentTimeLabel.addBorder(side: .right, color: GraphicColors.orange, width: 0.5)
		songControlView.addSubview(currentTimeLabel)
		currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
		currentTimeLabel.leadingAnchor.constraint(equalTo: progressBar.trailingAnchor, constant: 2.5).isActive = true
		currentTimeLabel.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.1, constant: -2.5).isActive = true
		currentTimeLabel.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
		currentTimeLabel.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true

		timeLeftLabel.addBorder(side: .left, color: GraphicColors.orange, width: 0.5)
		songControlView.addSubview(timeLeftLabel)
		timeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
		timeLeftLabel.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.1, constant: -2.5).isActive = true
		timeLeftLabel.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor).isActive = true
		timeLeftLabel.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
		timeLeftLabel.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true

		playbackRateButton.addTarget(self, action: #selector(playbackRateButtonAction), for: .touchUpInside)
		songControlView.addSubview(playbackRateButton)
		playbackRateButton.translatesAutoresizingMaskIntoConstraints = false
		playbackRateButton.leadingAnchor.constraint(equalTo: timeLeftLabel.trailingAnchor, constant: 2.5).isActive = true
		playbackRateButton.trailingAnchor.constraint(equalTo: songControlView.trailingAnchor, constant: -2.5).isActive = true
		playbackRateButton.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
		playbackRateButton.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true

		self.addSubview(thumbnailImageView)
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
		thumbnailImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 3.5).isActive = true
		thumbnailImageView.bottomAnchor.constraint(equalTo: songControlView.topAnchor, constant: -2.5).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 1.25).isActive = true

		thumbnailImageView.layer.cornerRadius = 5.0
        thumbnailImageView.layer.borderWidth = 1.0
        thumbnailImageView.layer.borderColor = UIColor.lightGray.cgColor
        
		nextButton.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
		self.addSubview(nextButton)
		nextButton.translatesAutoresizingMaskIntoConstraints = false
		nextButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
		nextButton.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor).isActive = true
		nextButton.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.25).isActive = true
		nextButton.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.25).isActive = true

		pausePlayButton.addTarget(self, action: #selector(pausePlayButtonAction), for: .touchUpInside)
		self.addSubview(pausePlayButton)
		pausePlayButton.translatesAutoresizingMaskIntoConstraints = false
		pausePlayButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -5).isActive = true
		pausePlayButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
		pausePlayButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor, multiplier: 1.5).isActive = true
		pausePlayButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor, multiplier: 1.5).isActive = true

		previousButton.addTarget(self, action: #selector(previousButtonAction), for: .touchUpInside)
		self.addSubview(previousButton)
		previousButton.translatesAutoresizingMaskIntoConstraints = false
		previousButton.trailingAnchor.constraint(equalTo: pausePlayButton.leadingAnchor, constant: -5).isActive = true
		previousButton.centerYAnchor.constraint(equalTo: pausePlayButton.centerYAnchor).isActive = true
		previousButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true
		previousButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true

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
	
	@objc func playbackRateButtonAction(sender: UIButton!) {
		print("playback rate Button tapped")
		if songID == "" {
			return
		}
		if sender.titleLabel?.text == "x1" {
			sender.setTitle("x1.25", for: .normal)
			audioPlayer.setPlayerRate(to: 1.25)
		} else if sender.titleLabel?.text == "x1.25" {
			sender.setTitle("x0.75", for: .normal)
			audioPlayer.setPlayerRate(to: 0.75)
		} else {
			sender.setTitle("x1", for: .normal)
			audioPlayer.setPlayerRate(to: 1)
		}
	}
	
	@objc func shuffleButtonAction(sender: UIButton!) {
		print("shuffle Button tapped")
		NPDelegate?.shufflePlaylist()
	}
	
	@objc func repeatButtonAction(sender: UIButton!) {
		print("repeat Button tapped")
		print("new repeat status: ", !audioPlayer.isSongRepeat)
		repeatButton.alpha = !audioPlayer.isSongRepeat ? 1 : 0.35
		audioPlayer.isSongRepeat = !audioPlayer.isSongRepeat
	}
	
	@objc func lyricsButtonAction(sender: UIButton!) {
		print("lyrics Button tapped")
		if lyricsTextView.text != "" {
			lyricsTextView.isHidden = !lyricsTextView.isHidden
			lyricsButton.isHidden = !lyricsButton.isHidden
		}
	}

	@objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
		if let touchEvent = event.allTouches?.first {
			switch touchEvent.phase {
				case .began:
				// handle drag began
					isProgressBarSliding = true
				break
				case .ended:
				// handle drag ended
					isProgressBarSliding = false
					if songID == "" {
						slider.value = 0.0
						return
					}
					audioPlayer.setPlayerCurrentTime(withPercentage: slider.value)
				case .moved:
				// handle drag moved
					let songDuration = Float((currentTimeLabel.text?.convertToTimeInterval())! + (timeLeftLabel.text?.convertToTimeInterval())!)
					let selectedTime = (songDuration * slider.value).rounded(.toNearestOrAwayFromZero)
					let timeLeft = (songDuration * (1 - slider.value)).rounded(.toNearestOrAwayFromZero)
					currentTimeLabel.text = TimeInterval(exactly: selectedTime)?.stringFromTimeInterval()
					timeLeftLabel.text = TimeInterval(exactly: timeLeft)?.stringFromTimeInterval()
				break
				default:
					break
			}
		}
	}
	
	func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float) {
		if !isProgressBarSliding {
			if duration == 0 {
				currentTimeLabel.text = "00:00"
				timeLeftLabel.text = "00:00"
				progressBar.value = 0.0
				return
			}
			currentTimeLabel.text = TimeInterval(exactly: currentTime)?.stringFromTimeInterval()
			timeLeftLabel.text = TimeInterval(exactly: duration-currentTime)?.stringFromTimeInterval()
			self.progressBar.value = currentTime/duration
		}
	}
	
	func audioPlayerPlayingStatusChanged(isPlaying: Bool) {
		if isPlaying {
			self.pausePlayButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
		} else {
			self.pausePlayButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
		}
	}

	fileprivate func makeCircleImage(radius: CGFloat, color: UIColor,
									 borderColor: UIColor, borderWidth: CGFloat) -> UIImage? {
		let outerSize = CGSize(width: radius, height: radius)
		let innerSize = CGSize(width: radius - 2.0 * borderWidth, height: radius - 2.0 * borderWidth)
		UIGraphicsBeginImageContextWithOptions(outerSize, false, 0.0)
		let context = UIGraphicsGetCurrentContext()
		let outerBounds = CGRect(origin: .zero, size: outerSize)
		context?.setFillColor(borderColor.cgColor)
		context?.setStrokeColor(UIColor.clear.cgColor)
		context?.addEllipse(in: outerBounds)
		context?.drawPath(using: .fill)
		let innerBounds = CGRect(x: borderWidth, y: borderWidth, width: innerSize.width, height: innerSize.height)
		context?.setFillColor(color.cgColor)
		context?.setStrokeColor(UIColor.clear.cgColor)
		context?.addEllipse(in: innerBounds)
		context?.drawPath(using: .fill)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
	
}
