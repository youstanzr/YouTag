//
//  YYTSlider.swift
//  YouTag
//
//  Created by Youstanzr on 2025-09-23.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import UIKit

class YYTRangeSlider: UIControl {

    // Internal track drawing layer kept private to this control
    private final class TrackLayer: CALayer {
        weak var owner: YYTRangeSlider?
        override func draw(in ctx: CGContext) {
            guard let slider = owner else { return }
            cornerRadius = bounds.height / 2.0
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
            ctx.addPath(path.cgPath)

            // Base track
            ctx.setFillColor(slider.trackTintColor.cgColor)
            ctx.fillPath()

            // Highlighted (selected) range
            ctx.setFillColor(slider.trackHighlightTintColor.cgColor)
            let lowerX = slider.positionForValue(slider.lowerValue)
            let upperX = slider.positionForValue(slider.upperValue)
            let rect = CGRect(x: lowerX, y: 0, width: upperX - lowerX, height: bounds.height)
            ctx.fill(rect)
        }
    }

    // Track heights (Apple-like subtle growth on interaction)
    private var normalTrackHeight: CGFloat = 4
    private var activeTrackHeight: CGFloat = 6
    private var _currentTrackHeight: CGFloat = 4

    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    var minimumValue: CGFloat = 0.0 {
        didSet {
            maximumValue = maximumValue == minimumValue ? minimumValue+0.00000001 : maximumValue
            updateLayerFrames()
        }
    }
    
    var maximumValue: CGFloat = 1.0 {
        didSet {
            maximumValue = maximumValue == minimumValue ? minimumValue+0.00000001 : maximumValue
            updateLayerFrames()
        }
    }
    
    var lowerValue: CGFloat = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var upperValue: CGFloat = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var trackTintColor = UIColor(white: 0.9, alpha: 1) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var trackHighlightTintColor = UIColor(red: 0, green: 0.45, blue: 0.94, alpha: 1) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var thumbColor: UIColor = UIColor.label.withAlphaComponent(0.85) {
        didSet {
            upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            updateLayerFrames()
        }
    }

    var thumbBorderColor: UIColor = .systemBackground {
        didSet {
            upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            updateLayerFrames()
        }
    }
    
    var thumbBorderWidth: CGFloat = 1.0 {
        didSet {
            upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            updateLayerFrames()
        }
    }

    var thumbSize: CGFloat = 16 {
        didSet {
            upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                        borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
            updateLayerFrames()
        }
    }
    
    var highlightedThumbSize: CGFloat = 20.0

    /// Minimum allowed distance between lowerValue and upperValue in value units (same units as min/max). Default 0 allows overlap.
    var minimumRange: CGFloat = 1

    /// Extra hit area around each thumb without affecting visual size
    var hitSlop: CGFloat = 16.0

    /// If true, dragging one thumb can push the other while respecting `minimumRange`.
    var isPushEnabled = true
    
    private let trackLayer = TrackLayer()
    private let lowerThumbImageView = UIImageView()
    private let upperThumbImageView = UIImageView()
    private var previousLocation = CGPoint()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        trackLayer.owner = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                    borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
        addSubview(lowerThumbImageView)
        
        upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
                                                    borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
        addSubview(upperThumbImageView)
        
        // Subtle depth on thumbs
        for v in [lowerThumbImageView, upperThumbImageView] {
            v.layer.shadowOpacity = 0.08
            v.layer.shadowRadius = 2
            v.layer.shadowOffset = CGSize(width: 0, height: 1)
        }
        
        updateLayerFrames()
        _currentTrackHeight = normalTrackHeight
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }
    
    private func animateTrackHeight(to height: CGFloat) {
        guard _currentTrackHeight != height else { return }
        _currentTrackHeight = height
        // Animate thumbs with a small spring; track layer doesn’t implicitly animate
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) {
            self.updateLayerFrames()
            self.layoutIfNeeded()
        }
    }

    private func updateLayerFrames() {
        // Track: redraw without implicit animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let trackY = (bounds.height - _currentTrackHeight) / 2
        trackLayer.frame = CGRect(x: 0, y: trackY, width: bounds.width, height: _currentTrackHeight)
        trackLayer.setNeedsDisplay()
        CATransaction.commit()

        // Thumbs: animate size changes with a gentle spring
        let lowerTargetSize = lowerThumbImageView.isHighlighted ? highlightedThumbSize : thumbSize
        let upperTargetSize = upperThumbImageView.isHighlighted ? highlightedThumbSize : thumbSize

        let lowerTargetFrame = CGRect(
            origin: thumbOriginForValue(lowerValue, thumbSize: lowerTargetSize),
            size: CGSize(width: lowerTargetSize, height: lowerTargetSize)
        )
        let upperTargetFrame = CGRect(
            origin: thumbOriginForValue(upperValue, thumbSize: upperTargetSize),
            size: CGSize(width: upperTargetSize, height: upperTargetSize)
        )

        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) {
            self.lowerThumbImageView.frame = lowerTargetFrame
            self.upperThumbImageView.frame = upperTargetFrame
        }
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        let normalizedVal = (value - minimumValue) / (maximumValue - minimumValue)
        return (normalizedVal * (bounds.width-thumbSize)) + thumbSize / 2.0
    }

    private func thumbOriginForValue(_ value: CGFloat, thumbSize: CGFloat) -> CGPoint {
        let x = positionForValue(value) - thumbSize / 2.0
        return CGPoint(x: x, y: (bounds.height - thumbSize) / 2.0)
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


extension YYTRangeSlider {

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {

        previousLocation = touch.location(in: self)

        let lowerHit = lowerThumbImageView.frame.insetBy(dx: -hitSlop, dy: -hitSlop).contains(previousLocation)
        let upperHit = upperThumbImageView.frame.insetBy(dx: -hitSlop, dy: -hitSlop).contains(previousLocation)

        if lowerHit && upperHit {
            // If touch is in both hit areas (thumbs close/overlapping), pick the nearest center
            let lowerDist = abs(previousLocation.x - lowerThumbImageView.center.x)
            let upperDist = abs(previousLocation.x - upperThumbImageView.center.x)
            if lowerDist <= upperDist {
                lowerThumbImageView.isHighlighted = true
            } else {
                upperThumbImageView.isHighlighted = true
            }
        } else if lowerHit {
            lowerThumbImageView.isHighlighted = true
        } else if upperHit {
            upperThumbImageView.isHighlighted = true
        }

        animateTrackHeight(to: activeTrackHeight)
        updateLayerFrames()
        return lowerThumbImageView.isHighlighted || upperThumbImageView.isHighlighted
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        guard (maximumValue - minimumValue) > 0.000000011 else { return true }

        let deltaLocation = location.x - previousLocation.x
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / bounds.width
        previousLocation = location

        let minRange = max(0, minimumRange)

        if upperThumbImageView.isHighlighted {
            var newUpper = upperValue + deltaValue
            if isPushEnabled {
                // push lower while keeping at least minRange
                let desiredLower = min(lowerValue, newUpper - minRange)
                let pushedLower = min(max(desiredLower, minimumValue), newUpper - minRange)
                // If lower needs to move, move it by the same delta if possible
                if pushedLower < lowerValue { lowerValue = pushedLower }
            }
            newUpper = min(max(newUpper, lowerValue + minRange), maximumValue)
            upperValue = newUpper
        } else if lowerThumbImageView.isHighlighted {
            var newLower = lowerValue + deltaValue
            if isPushEnabled {
                // push upper while keeping at least minRange
                let desiredUpper = max(upperValue, newLower + minRange)
                let pushedUpper = max(min(desiredUpper, maximumValue), newLower + minRange)
                if pushedUpper > upperValue { upperValue = pushedUpper }
            }
            newLower = max(min(newLower, upperValue - minRange), minimumValue)
            lowerValue = newLower
        }

        updateLayerFrames()

        sendActions(for: .valueChanged)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbImageView.isHighlighted = false
        upperThumbImageView.isHighlighted = false
        animateTrackHeight(to: normalTrackHeight)
        updateLayerFrames()
    }
    
    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        lowerThumbImageView.isHighlighted = false
        upperThumbImageView.isHighlighted = false
        animateTrackHeight(to: normalTrackHeight)
        updateLayerFrames()
    }
    
    private func boundValue(_ value: CGFloat, toLowerValue lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        return min(max(value, lowerValue), upperValue)
    }

    /// Sets the allowed range in the same units as `minimumValue`/`maximumValue`.
    func setMinimumRange(_ value: CGFloat) {
        minimumRange = max(0, value)
        // Re-clamp current values to honor the new rule
        lowerValue = max(min(lowerValue, upperValue - minimumRange), minimumValue)
        upperValue = min(max(upperValue, lowerValue + minimumRange), maximumValue)
        updateLayerFrames()
    }
    
}
