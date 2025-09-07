//
//  PlaylistControlView.swift
//  YouTag
//
//  Created by Yousef AlQattan on 2025-09-01.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import UIKit

protocol PlaylistControlViewDelegate: AnyObject {
    func playlistControlViewDidTapShuffle(_ view: PlaylistControlView)
    func playlistControlView(_ view: PlaylistControlView,
                             didToggleRepeat isOn: Bool)
}

extension Notification.Name {
    static let playlistControlLyricsToggled = Notification.Name("playlistControlLyricsToggled")
}

class PlaylistControlView: UIView {

    weak var PCdelegate: PlaylistControlViewDelegate?

    private let repeatButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "loop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        btn.alpha = 0.35
        return btn
    }()

    private let shuffleButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.imageView!.contentMode = .scaleAspectFit
        btn.setImage(UIImage(named: "shuffle")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = GraphicColors.cloudWhite
        return btn
    }()

    private let lyricsButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 24)
        btn.setTitle("What's next", for: .normal)
        btn.setTitleColor(GraphicColors.orange, for: .normal)
        return btn
    }()

    private let lyricsTextView: UITextView = {
        let txtView = UITextView()
        txtView.textColor = GraphicColors.cloudWhite
        txtView.backgroundColor = GraphicColors.darkGray.withAlphaComponent(0.08)
        txtView.textAlignment = .center
        txtView.font = UIFont.init(name: "Optima-BoldItalic", size: 15)
        txtView.isEditable = false
        txtView.isSelectable = false
        txtView.isHidden = true
        return txtView
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Public
    func configure(lyrics: String?) {
        let hasLyrics = !(lyrics?.isEmpty ?? true)
        lyricsTextView.text = lyrics
        lyricsTextView.isHidden = !hasLyrics
        lyricsButton.isHidden = hasLyrics
        NotificationCenter.default.post(
            name: .playlistControlLyricsToggled,
            object: self,
            userInfo: ["isShown": hasLyrics]
        )
    }

    // MARK: - UI
    private func setupUI() {
        addBorder(side: .top, color: GraphicColors.darkGray, width: 0.5)

        addSubview(repeatButton)
        addSubview(shuffleButton)
        addSubview(lyricsButton)
        addSubview(lyricsTextView)

        [repeatButton, shuffleButton, lyricsButton, lyricsTextView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // Layout
        repeatButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2.5).isActive = true
        repeatButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.125).isActive = true
        repeatButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        repeatButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        shuffleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2.5).isActive = true
        shuffleButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.125).isActive = true
        shuffleButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        shuffleButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        lyricsButton.leadingAnchor.constraint(equalTo: repeatButton.trailingAnchor, constant: 2.5).isActive = true
        lyricsButton.trailingAnchor.constraint(equalTo: shuffleButton.leadingAnchor, constant: -2.5).isActive = true
        lyricsButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        lyricsButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        lyricsTextView.leadingAnchor.constraint(equalTo: lyricsButton.leadingAnchor).isActive = true
        lyricsTextView.trailingAnchor.constraint(equalTo: lyricsButton.trailingAnchor).isActive = true
        lyricsTextView.topAnchor.constraint(equalTo: lyricsButton.topAnchor).isActive = true
        lyricsTextView.bottomAnchor.constraint(equalTo: lyricsButton.bottomAnchor).isActive = true

        // Actions
        repeatButton.addTarget(self, action: #selector(repeatTapped), for: .touchUpInside)
        shuffleButton.addTarget(self, action: #selector(shuffleTapped), for: .touchUpInside)
        lyricsButton.addTarget(self, action: #selector(toggleLyrics), for: .touchUpInside)
        lyricsTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleLyrics)))
    }

    // MARK: - Actions
    @objc private func shuffleTapped() {
        PCdelegate?.playlistControlViewDidTapShuffle(self)
    }

    @objc private func repeatTapped() {
        let isOn = !(abs(repeatButton.alpha - 1.0) < 0.01)
        setRepeat(isOn: isOn)
        PCdelegate?.playlistControlView(self, didToggleRepeat: isOn)
    }
    
    func setRepeat(isOn: Bool) {
        repeatButton.alpha = isOn ? 1.0 : 0.35
    }

    @objc private func toggleLyrics() {
        if lyricsTextView.text.isEmpty { return }
        lyricsTextView.isHidden.toggle()
        lyricsButton.isHidden.toggle()
        NotificationCenter.default.post(
            name: .playlistControlLyricsToggled,
            object: self,
            userInfo: ["isShown": !lyricsTextView.isHidden]
        )
    }
}
