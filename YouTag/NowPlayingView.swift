//
//  NowPlayingView.swift
//  YouTag
//
//  Created by Youstanzr on 8/13/19.
//  Copyright © 2019 Youstanzr. All rights reserved.
//
import UIKit
import MarqueeLabel

protocol NowPlayingViewDelegate: AnyObject {
    func shufflePlaylist()
    func audioPlayerDidFinishTrack()
}

class NowPlayingView: UIView, YYTAudioPlayerDelegate {
    
    weak var NPDelegate: NowPlayingViewDelegate?
    var audioPlayer: YYTAudioPlayer!
    var currentSong: Song?
    
    let thumbnailImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 5.0
        imgView.layer.borderWidth = 0.5
        imgView.layer.borderColor = GraphicColors.darkGray.cgColor
        imgView.layer.masksToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    let titleLabel: MarqueeLabel = {
        let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
        lbl.textColor = GraphicColors.cloudWhite
        lbl.trailingBuffer = 40.0
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 22)
        lbl.textAlignment = .left
        return lbl
    }()
    
    let subLabel: MarqueeLabel = {
        let lbl = MarqueeLabel.init(frame: .zero, rate: 45.0, fadeLength: 10.0)
        lbl.textColor = GraphicColors.medGray
        lbl.trailingBuffer = 40.0
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 16)
        lbl.textAlignment = .left
        return lbl
    }()
    let tagView: YYTTagView = {
        let style = TagViewStyle(
            isAddEnabled: false,
            isMultiSelection: false,
            isDeleteEnabled: false,
            showsBorder: false,
            cellFont: UIFont(name: "Damascus", size: 14)!,
            overflow: .truncateTail,
            horizontalPadding: 0,
            verticalPadding: 0,
            cellHorizontalPadding: 15,
            cellBorderWidth: 1,
            cellTextColor: GraphicColors.medGray
        )
        let view = YYTTagView(
            frame: .zero,
            tagsList: [],
            suggestionDataSource: nil,
            style: style
        )
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    let previousButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "previous")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        return btn
    }()
    let pausePlayButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        return btn
    }()
    let nextButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "next")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
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
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 14)
        btn.setTitle("x1", for: .normal)
        return btn
    }()
    
    let currentTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = GraphicColors.medGray
        lbl.text = "00:00"
        lbl.textAlignment = .center
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 14)
        return lbl
    }()
    let timeLeftLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = GraphicColors.medGray
        lbl.text = "00:00"
        lbl.textAlignment = .center
        lbl.font = UIFont(name: "DINAlternate-Bold", size: 14)
        return lbl
    }()
    
    weak var playlistControlView: PlaylistControlView?
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, audioPlayer: YYTAudioPlayer) {
        super.init(frame: frame)
        self.audioPlayer = audioPlayer
        self.audioPlayer.delegate = self
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        songControlView.addBorder(side: .top, color: GraphicColors.darkGray, width: 0.5)
        self.addSubview(songControlView)
        songControlView.translatesAutoresizingMaskIntoConstraints = false
        songControlView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        songControlView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        songControlView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        songControlView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        songControlView.addSubview(progressBar)
        songControlView.addSubview(currentTimeLabel)
        songControlView.addSubview(timeLeftLabel)
        songControlView.addSubview(playbackRateButton)

        let thumbImage = makeCircleImage(radius: 20.0, color: GraphicColors.medGray, borderColor: .clear, borderWidth: 0.0)
        let selectedThumbImage = makeCircleImage(radius: 25.0, color: GraphicColors.darkGray, borderColor: .clear, borderWidth: 0.0)
        progressBar.setThumbImage(thumbImage, for: .normal)
        progressBar.setThumbImage(selectedThumbImage, for: .highlighted)
        progressBar.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.leadingAnchor.constraint(equalTo: songControlView.leadingAnchor, constant: 5.0).isActive = true
        progressBar.trailingAnchor.constraint(equalTo: currentTimeLabel.leadingAnchor, constant: -5.0).isActive = true
        progressBar.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
        
        currentTimeLabel.addBorder(side: .right, color: GraphicColors.orange, width: 0.5)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.trailingAnchor.constraint(equalTo: timeLeftLabel.leadingAnchor).isActive = true
        currentTimeLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        currentTimeLabel.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        currentTimeLabel.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
        
        timeLeftLabel.addBorder(side: .left, color: GraphicColors.orange, width: 0.5)
        timeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLeftLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        timeLeftLabel.trailingAnchor.constraint(equalTo: playbackRateButton.leadingAnchor).isActive = true
        timeLeftLabel.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        timeLeftLabel.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
        
        playbackRateButton.addTarget(self, action: #selector(playbackRateButtonAction), for: .touchUpInside)
        playbackRateButton.translatesAutoresizingMaskIntoConstraints = false
        playbackRateButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        playbackRateButton.trailingAnchor.constraint(equalTo: songControlView.trailingAnchor, constant: -2.5).isActive = true
        playbackRateButton.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        playbackRateButton.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
        
        self.addSubview(thumbnailImageView)
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
        thumbnailImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 3.5).isActive = true
        thumbnailImageView.bottomAnchor.constraint(equalTo: songControlView.topAnchor, constant: -2.5).isActive = true
        thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0 / 3.0).isActive = true
        
        thumbnailImageView.layer.cornerRadius = 5.0
        thumbnailImageView.layer.borderWidth = 0.5
        thumbnailImageView.layer.borderColor = GraphicColors.lightGray.cgColor
        
        nextButton.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
        // Long-press to continuously seek forward
        let nextLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleNextLongPress(_:)))
        nextLongPress.minimumPressDuration = 0.5
        nextLongPress.cancelsTouchesInView = true   // prevent .touchUpInside after a long press
        nextLongPress.allowableMovement = 20
        nextButton.addGestureRecognizer(nextLongPress)
        self.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
        nextButton.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor).isActive = true
        nextButton.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.25).isActive = true
        nextButton.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.25).isActive = true
        nextButton.heightAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        nextButton.widthAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        
        pausePlayButton.addTarget(self, action: #selector(pausePlayButtonAction), for: .touchUpInside)
        self.addSubview(pausePlayButton)
        pausePlayButton.translatesAutoresizingMaskIntoConstraints = false
        pausePlayButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -5).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
        pausePlayButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor, multiplier: 1.5).isActive = true
        pausePlayButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor, multiplier: 1.5).isActive = true
        pausePlayButton.heightAnchor.constraint(lessThanOrEqualToConstant: 90).isActive = true
        pausePlayButton.widthAnchor.constraint(lessThanOrEqualToConstant: 90).isActive = true
        
        previousButton.addTarget(self, action: #selector(previousButtonAction), for: .touchUpInside)
        // Long-press to continuously seek backward
        let prevLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handlePreviousLongPress(_:)))
        prevLongPress.minimumPressDuration = 0.5
        prevLongPress.cancelsTouchesInView = true   // prevent .touchUpInside after a long press
        prevLongPress.allowableMovement = 20
        previousButton.addGestureRecognizer(prevLongPress)
        self.addSubview(previousButton)
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.trailingAnchor.constraint(equalTo: pausePlayButton.leadingAnchor, constant: -5).isActive = true
        previousButton.centerYAnchor.constraint(equalTo: pausePlayButton.centerYAnchor).isActive = true
        previousButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true
        previousButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor).isActive = true
        previousButton.heightAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        previousButton.widthAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        
        //        titleLabel.backgroundColor = .blue
        //        subLabel.backgroundColor = .red
        //        tagView.backgroundColor = .yellow
        
        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: -5).isActive = true
        titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 2.5).isActive = true
        titleLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.38, constant: -5).isActive = true
        
        self.addSubview(subLabel)
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2.5).isActive = true
        subLabel.heightAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 0.27).isActive = true
        
        // Add tag view
        self.addSubview(tagView)
        tagView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        tagView.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: -5).isActive = true
        tagView.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 5).isActive = true
        tagView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -2.5).isActive = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Defer to next runloop to avoid doing work mid-transition
        DispatchQueue.main.async { [weak self] in self?.invalidateTagLayout() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // If bounds changed significantly (e.g., rotation), refresh layout
        invalidateTagLayout()
    }

    // MARK: - Layout Maintenance
    private func invalidateTagLayout() {
        guard !tagView.isHidden else { return }
        // Ensure the collection view recomputes cell sizes on size-class/orientation changes
        tagView.collectionView.collectionViewLayout.invalidateLayout()
        tagView.collectionView.reloadData()
    }

    
    // MARK: - Load Song
    func loadSong(song: Song, preparePlayer: Bool = true) {
        currentSong = song
        titleLabel.text = song.title
        // Build subLabel as "Artist • Album • Year"
        let parts = [
            song.album ?? "",
            song.releaseYear ?? "",
            song.artists.joined(separator: ", "),
        ].filter { !$0.isEmpty }
        subLabel.text = parts.joined(separator: "  •  ")
        
        playlistControlView?.configure(lyrics: song.lyrics)
        
        // Restart marquee and set direction based on text
        titleLabel.restartLabel()
        if titleLabel.text!.isRTL {
            titleLabel.type = .continuousReverse
        } else {
            titleLabel.type = .continuous
        }
        
        subLabel.restartLabel()
        if subLabel.text!.isRTL {
            subLabel.type = .continuousReverse
        } else {
            subLabel.type = .continuous
        }
        
        // Update tag view visibility and data
        if !song.tags.isEmpty {
            tagView.isHidden = false
            tagView.tagsList = song.tags
            tagView.collectionView.reloadData()
        } else {
            tagView.isHidden = true
        }
        
        // Update thumbnail
        thumbnailImageView.image = LibraryManager.shared.fetchThumbnail(for: song)
        ?? UIImage(named: "placeholder")
                
        // Prepare the player without auto-playing
        if preparePlayer, audioPlayer.setupPlayer(withSong: song) {
            // Reset UI
            progressBar.value = 0.0
            currentTimeLabel.text = "00:00"
            timeLeftLabel.text = song.duration
        }
    }
    
    func clearNowPlaying() {
        currentSong = nil
        audioPlayer.clearPlayback()
        audioPlayer.setPlaybackRate(to: 1.0)
        playbackRateButton.setTitle("x1", for: .normal)
        titleLabel.text = ""
        subLabel.text = ""
        thumbnailImageView.image = nil
        progressBar.value = 0.0
        currentTimeLabel.text = "00:00"
        timeLeftLabel.text = "00:00"
        tagView.tagsList.removeAll()
    }
    
    // MARK: - Button Actions
    @objc func pausePlayButtonAction() {
        if audioPlayer.isPlaying() {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    @objc func nextButtonAction() {
        audioPlayer.next()
    }
    
    @objc func previousButtonAction() {
        audioPlayer.prev()
    }
    
    // MARK: - Long-press Seeking Integration
    @objc private func handleNextLongPress(_ gr: UILongPressGestureRecognizer) {
        switch gr.state {
        case .began:
            audioPlayer.startContinuousSeek(direction: .forward)
        case .ended, .cancelled, .failed:
            audioPlayer.stopContinuousSeek()
        default:
            break
        }
    }
    
    @objc private func handlePreviousLongPress(_ gr: UILongPressGestureRecognizer) {
        switch gr.state {
        case .began:
            audioPlayer.startContinuousSeek(direction: .backward)
        case .ended, .cancelled, .failed:
            audioPlayer.stopContinuousSeek()
        default:
            break
        }
    }
    
    @objc func playbackRateButtonAction() {
        // Determine current rate from button title (fallback to 1.0)
        let currentTitle = playbackRateButton.title(for: .normal) ?? "x1"
        let currentRate = Float(currentTitle.replacingOccurrences(of: "x", with: "")) ?? 1.0
        
        let hostView: UIView = self.window ?? self
        let popup = PlaybackRateView(currentRate: currentRate)
        popup.onApply = { [weak self] newRate in
            guard let self = self else { return }
            self.audioPlayer.setPlaybackRate(to: newRate)
            self.playbackRateButton.setTitle("x\(self.formatRate(newRate))", for: .normal)
        }
        popup.present(over: hostView)
    }

    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                isProgressBarSliding = true
                break
            case .ended:
                isProgressBarSliding = false
                guard let _ = currentSong else {
                    slider.value = 0.0
                    return
                }
                audioPlayer.seek(toPercentage: slider.value)
            case .moved:
                let selectedTime = (slider.value * audioPlayer.duration()).rounded()
                let timeLeft = ((1 - slider.value) * audioPlayer.duration()).rounded()
                currentTimeLabel.text = TimeInterval(selectedTime).stringFromTimeInterval()
                timeLeftLabel.text = TimeInterval(timeLeft).stringFromTimeInterval()
            default:
                break
            }
        }
    }
    
    // MARK: - Audio Player Delegate
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float) {
        // Refresh Control Center elapsed time
        audioPlayer.updateNowPlaying(isPaused: !audioPlayer.isPlaying())
        if !isProgressBarSliding {
            if duration == 0 {
                currentTimeLabel.text = "00:00"
                timeLeftLabel.text = "00:00"
                progressBar.value = 0.0
                return
            }
            currentTimeLabel.text = TimeInterval(currentTime).stringFromTimeInterval()
            timeLeftLabel.text = TimeInterval(duration - currentTime).stringFromTimeInterval()
            progressBar.value = currentTime / duration
        }
    }
    
    func audioPlayerPlayingStatusChanged(isPlaying: Bool) {
        let imageName = isPlaying ? "pause" : "play"
        pausePlayButton.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    func audioPlayerDidFinishTrack() {
        NPDelegate?.audioPlayerDidFinishTrack()
    }
    
    // Helper to format playback rate (e.g. 1, 1.25, 1.5)
    private func formatRate(_ rate: Float) -> String {
        // Format like 1, 1.25, 1.5 (trim trailing zeros)
        let s = String(format: "%.2f", rate)
        return s.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }
    
    // MARK: - Helper Function
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
    
    // MARK: - External Playlist View Connection
    func connectPlaylistControlView(_ view: PlaylistControlView) {
        self.playlistControlView = view
    }
    
}
