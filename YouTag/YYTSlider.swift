//
//  YYTSlider.swift
//  YouTag
//
//  Created by Youstanzr on 2025-09-23.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import UIKit

/// Slider with no thumb; track thickens while dragging.
final class YYTSlider: UISlider {

    // MARK: - Public styling

    var normalTrackHeight: CGFloat = 5 { didSet { if !isTracking { setNeedsLayout() } } }
    var highlightedTrackHeight: CGFloat = 7 { didSet { if isTracking { setNeedsLayout() } } }
    var hitTargetInset: CGFloat = 14

    // MARK: - Private

    private var isInteracting = false
    private var currentTrackHeight: CGFloat { isInteracting ? highlightedTrackHeight : normalTrackHeight }

    private lazy var invisibleThumb: UIImage = {
        let size = CGSize(width: 1, height: 1)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in UIColor.clear.setFill(); UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill() }
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        minimumTrackTintColor = .systemOrange
        maximumTrackTintColor = UIColor.label.withAlphaComponent(0.25)

        setThumbImage(invisibleThumb, for: .normal)
        setThumbImage(invisibleThumb, for: .highlighted)
        setThumbImage(invisibleThumb, for: .focused)
        setThumbImage(invisibleThumb, for: .disabled)

        addTarget(self, action: #selector(handleTrackingBegin), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTrackingEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    // MARK: - Public convenience

    func applyStyle(minTrackColor: UIColor, maxTrackColor: UIColor, trackHeight: CGFloat, highlightedHeight: CGFloat? = nil) {
        self.minimumTrackTintColor = minTrackColor
        self.maximumTrackTintColor = maxTrackColor
        self.normalTrackHeight = trackHeight
        if let h = highlightedHeight { self.highlightedTrackHeight = h }
        setNeedsLayout()
    }

    // MARK: - UISlider overrides

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let r = super.trackRect(forBounds: bounds)
        return CGRect(x: r.origin.x, y: r.midY - currentTrackHeight/2, width: r.width, height: currentTrackHeight)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let larger = bounds.insetBy(dx: -hitTargetInset, dy: -hitTargetInset)
        return larger.contains(point)
    }

    @objc private func handleTrackingBegin() {
        guard !isInteracting else { return }
        isInteracting = true
        animateTrackHeightChange()
    }

    @objc private func handleTrackingEnd() {
        guard isInteracting else { return }
        isInteracting = false
        animateTrackHeightChange()
    }

    // MARK: - Animation

    private func animateTrackHeightChange() {
        // Animate track height change
        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}
