//
//  PlaybackRateView.swift
//  YouTag
//
//  Created by Yousef AlQattan on 2025-08-12.
//  Copyright © 2025 Youstanzr. All rights reserved.
//
import UIKit

final class PlaybackRateView: UIView {
    // Callbacks
    var onApply: ((Float) -> Void)?

    // UI
    private let backdrop = UIView()
    private let card = UIView()
    private let titleLabel = UILabel()
    private let slider = UISlider()
    private let valueLabel = UILabel()
    private let buttonsStack = UIStackView()

    // Data
    private let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private var selectedRate: Float

    // Colors/Fonts
    private let accent = GraphicColors.orange
    private let textColor = GraphicColors.cloudWhite

    init(currentRate: Float) {
        self.selectedRate = currentRate
        super.init(frame: .zero)
        setupUI()
        setRate(currentRate, animated: false)
    }

    required init?(coder: NSCoder) {
        self.selectedRate = 1.0
        super.init(coder: coder)
        setupUI()
        setRate(1.0, animated: false)
    }

    func present(over host: UIView) {
        self.frame = host.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
        backdrop.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 300)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
            self.backdrop.alpha = 1
            self.card.transform = .identity
        } completion: { _ in }
    }

    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.2, animations: {
            self.backdrop.alpha = 0
            self.card.transform = CGAffineTransform(translationX: 0, y: 300)
        }) { _ in
            self.removeFromSuperview()
        }
    }


    @objc private func sliderChanged(_ s: UISlider) {
        let snapped = (s.value / 0.05).rounded() * 0.05
        setRate(snapped, animated: false)
    }

    @objc private func presetTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < rates.count else { return }
        let rate = rates[sender.tag]
        setRate(rate, animated: true)
    }

    private func setupUI() {
        // Backdrop
        backdrop.backgroundColor = GraphicColors.obsidianBlack.withAlphaComponent(0.85)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        backdrop.addGestureRecognizer(tap)

        // Card
        card.backgroundColor = GraphicColors.obsidianBlack
        card.layer.cornerRadius = 12
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])

        // Title
        titleLabel.text = "Playback speed"
        titleLabel.textColor = textColor
        titleLabel.font = UIFont(name: "DINAlternate-Bold", size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Value label
        valueLabel.textColor = GraphicColors.medGray
        valueLabel.font = UIFont(name: "DINAlternate-Bold", size: 14)
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        // Slider
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        slider.value = max(0.5, min(2.0, selectedRate))
        slider.isContinuous = true
        slider.tintColor = accent
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false

        // Preset buttons row (single row)
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 8
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        for (i, r) in rates.enumerated() {
            let btn = makePresetButton(title: rateText(r))
            btn.tag = i
            btn.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
            buttonsStack.addArrangedSubview(btn)
        }

        // Layout inside card
        card.addSubview(titleLabel)
        card.addSubview(valueLabel)
        card.addSubview(buttonsStack)
        card.addSubview(slider)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

            buttonsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            buttonsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            slider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            slider.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 14),
            slider.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
    }

    private func setRate(_ rate: Float, animated: Bool) {
        // Clamp and snap to 0.05 steps within 0.25–4.0
        var r = max(0.5, min(2.0, rate))
        r = (r / 0.05).rounded() * 0.05
        selectedRate = r
        if animated {
            UIView.animate(withDuration: 0.12) { self.slider.setValue(r, animated: true) }
        } else {
            slider.value = r
        }
        valueLabel.text = String(format: "%.2fx", r)
        refreshPresetSelection()
        onApply?(selectedRate)
    }

    private func refreshPresetSelection() {
        // Highlight button whose title matches selectedRate
        let allButtons = buttonsStack.arrangedSubviews.compactMap { $0 as? UIStackView }.flatMap { $0.arrangedSubviews }.compactMap { $0 as? UIButton }
        for b in allButtons {
            let isSelected = (b.currentTitle == "x\(format(selectedRate))")
            stylePresetButton(b, selected: isSelected)
        }
    }

    private func makePresetButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 14)
        b.layer.cornerRadius = 8
        b.layer.borderWidth = 1
        b.layer.borderColor = accent.cgColor
        b.setTitleColor(textColor, for: .normal)
        b.backgroundColor = .clear
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return b
    }

    private func stylePresetButton(_ b: UIButton, selected: Bool) {
        if selected {
            b.backgroundColor = accent
            b.setTitleColor(.black, for: .normal)
        } else {
            b.backgroundColor = .clear
            b.setTitleColor(textColor, for: .normal)
        }
    }

    private func makeActionButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 15)
        b.layer.cornerRadius = 9
        b.layer.borderWidth = 1
        b.layer.borderColor = accent.cgColor
        b.setTitleColor(textColor, for: .normal)
        b.backgroundColor = .clear
        return b
    }

    private func rateText(_ r: Float) -> String { "x\(format(r))" }
    private func format(_ r: Float) -> String {
        let s = String(format: "%.2f", r)
        return s.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }
}
