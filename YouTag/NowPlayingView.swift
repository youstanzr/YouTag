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

protocol NowPlayingLayoutDelegate: AnyObject {
    func nowPlayingView(_ view: NowPlayingView,
                        didToggleExpanded isExpanded: Bool,
                        collapsedPlaylistHeight: CGFloat,
                        expandedPlaylistHeight: CGFloat)
}

class NowPlayingView: UIView, YYTAudioPlayerDelegate {

    weak var NPDelegate: NowPlayingViewDelegate?
    weak var layoutDelegate: NowPlayingLayoutDelegate?
    var audioPlayer: YYTAudioPlayer!
    var currentSong: Song?
    /// Skip the very first periodic callback after loading a song
    private var skipNextPeriodicUpdate = false
    // Single height constraint for playlistControlView that we adjust directly
    private var playlistHeightConstraint: NSLayoutConstraint!
    private var collapsedPlaylistHeight: CGFloat = 0
    private var expandedPlaylistHeight: CGFloat = 0
    private var didInitPlaylistHeights = false
    // Tracks whether playlist area is currently expanded
    private var isPlaylistExpanded: Bool = false
    
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
        txtView.textColor = GraphicColors.cloudWhite
        txtView.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.08)
        txtView.textAlignment = .center
        txtView.font = UIFont.init(name: "Optima-BoldItalic", size: 15)
        txtView.isEditable = false
        txtView.isSelectable = false
        return txtView
    }()
    
    let repeatButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "loop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        btn.alpha = 0.35
        return btn
    }()
    let shuffleButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "shuffle")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        return btn
    }()

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
        playlistControlView.addBorder(side: .top, color: GraphicColors.darkGray, width: 0.5)
        self.addSubview(playlistControlView)
        playlistControlView.translatesAutoresizingMaskIntoConstraints = false
        playlistControlView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        playlistControlView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        playlistControlView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        // Start with a placeholder constant; we'll capture the actual collapsed height after first layout
        playlistHeightConstraint = playlistControlView.heightAnchor.constraint(equalToConstant: 0)
        playlistHeightConstraint.isActive = true

        playlistHeightConstraint.identifier = "NPC_playlist_height_const"

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

        songControlView.addBorder(side: .top, color: GraphicColors.darkGray, width: 0.5)
        self.addSubview(songControlView)
        songControlView.translatesAutoresizingMaskIntoConstraints = false
        songControlView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        songControlView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        songControlView.bottomAnchor.constraint(equalTo: playlistControlView.topAnchor).isActive = true
        songControlView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let thumbImage = makeCircleImage(radius: 20.0, color: GraphicColors.medGray, borderColor: .clear, borderWidth: 0.0)
        let selectedThumbImage = makeCircleImage(radius: 25.0, color: GraphicColors.darkGray, borderColor: .clear, borderWidth: 0.0)
        progressBar.setThumbImage(thumbImage, for: .normal)
        progressBar.setThumbImage(selectedThumbImage, for: .highlighted)
        progressBar.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        songControlView.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.leadingAnchor.constraint(equalTo: songControlView.leadingAnchor, constant: 10.0).isActive = true
        progressBar.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.63, constant: -2.5).isActive = true
        progressBar.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true
        
        currentTimeLabel.addBorder(side: .right, color: GraphicColors.orange, width: 0.5)
        songControlView.addSubview(currentTimeLabel)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.leadingAnchor.constraint(equalTo: progressBar.trailingAnchor, constant: 2.5).isActive = true
        currentTimeLabel.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.12, constant: -2.5).isActive = true
        currentTimeLabel.centerYAnchor.constraint(equalTo: songControlView.centerYAnchor).isActive = true
        currentTimeLabel.heightAnchor.constraint(equalTo: songControlView.heightAnchor).isActive = true

        timeLeftLabel.addBorder(side: .left, color: GraphicColors.orange, width: 0.5)
        songControlView.addSubview(timeLeftLabel)
        timeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLeftLabel.widthAnchor.constraint(equalTo: songControlView.widthAnchor, multiplier: 0.12, constant: -2.5).isActive = true
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
        thumbnailImageView.layer.borderWidth = 0.5
        thumbnailImageView.layer.borderColor = GraphicColors.lightGray.cgColor
        
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

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didInitPlaylistHeights else { return }
        didInitPlaylistHeights = true
        // Use the current laid-out height as the collapsed height
        let current = self.bounds.height * 0.4
        collapsedPlaylistHeight = current
        expandedPlaylistHeight = current * 2
        // Apply the correct initial constant (expanded if needed)
        playlistHeightConstraint.constant = isPlaylistExpanded ? expandedPlaylistHeight : collapsedPlaylistHeight
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

        // Configure lyrics view visibility
        lyricsTextView.text = song.lyrics
        let hasLyrics = !(song.lyrics?.isEmpty ?? true)
        lyricsTextView.isHidden = !hasLyrics
        lyricsButton.isHidden = hasLyrics
        setPlaylistAreaExpanded(hasLyrics, animated: false)
        
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
        
        // Skip the first periodic update after loading a new song
        skipNextPeriodicUpdate = true

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
    
    @objc func shuffleButtonAction() { NPDelegate?.shufflePlaylist() }
    @objc func repeatButtonAction() {
        audioPlayer.isSongRepeat.toggle()
        repeatButton.alpha = audioPlayer.isSongRepeat ? 1 : 0.35
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
                audioPlayer.setCurrentTime(to: slider.value)
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

    @objc func lyricsButtonAction() {
        if lyricsTextView.text != "" {
            let shouldShow = lyricsTextView.isHidden
            lyricsTextView.isHidden.toggle()
            lyricsButton.isHidden.toggle()
            setPlaylistAreaExpanded(shouldShow, animated: true)
        }
    }

    private func setPlaylistAreaExpanded(_ expanded: Bool, animated: Bool) {
        print("setPlaylistAreaExpanded: \(expanded)")
        isPlaylistExpanded = expanded
        playlistHeightConstraint.constant = expanded ? expandedPlaylistHeight : collapsedPlaylistHeight
    
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        
        broadcastLayoutState()
    }

    public func broadcastLayoutState() {
        print("broadcastLayoutState")
        // Ensure baseline heights exist
        if collapsedPlaylistHeight == 0 || expandedPlaylistHeight == 0 {
            let current = max(30, playlistControlView.bounds.height)
            let base = current > 0 ? current : max(30, self.bounds.height * 0.4)
            collapsedPlaylistHeight = base
            expandedPlaylistHeight = base * 2
        }
        layoutDelegate?.nowPlayingView(self,
                                       didToggleExpanded: isPlaylistExpanded,
                                       collapsedPlaylistHeight: collapsedPlaylistHeight,
                                       expandedPlaylistHeight: expandedPlaylistHeight)
    }

    // MARK: - Audio Player Delegate
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float) {
        // If we've just loaded a song, skip this first callback
        if skipNextPeriodicUpdate {
            skipNextPeriodicUpdate = false
            return
        }
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
    
}
