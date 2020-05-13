/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class YYTRangeSlider: UIControl {

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
	
	var thumbColor: UIColor = .lightGray {
		didSet {
			upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			updateLayerFrames()
		}
	}

	var thumbBorderColor: UIColor = .darkGray {
		didSet {
			upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			updateLayerFrames()
		}
	}
	
	var thumbBorderWidth: CGFloat = 0.0 {
		didSet {
			upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			updateLayerFrames()
		}
	}

	var thumbSize: CGFloat = 20 {
		didSet {
			upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
														borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
			updateLayerFrames()
		}
	}
	
	var highlightedThumbSize: CGFloat = 25.0
	var isPushEnabled = true
	
	private let trackLayer = YYTRangeSliderTrackLayer()
	private let lowerThumbImageView = UIImageView()
	private let upperThumbImageView = UIImageView()
	private var previousLocation = CGPoint()
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		trackLayer.rangeSlider = self
		trackLayer.contentsScale = UIScreen.main.scale
		layer.addSublayer(trackLayer)
		
		lowerThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
													borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
		addSubview(lowerThumbImageView)
		
		upperThumbImageView.image = makeCircleImage(radius: thumbSize, color: thumbColor,
													borderColor: thumbBorderColor, borderWidth: thumbBorderWidth)
		addSubview(upperThumbImageView)
		
		updateLayerFrames()
	}
	
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		updateLayerFrames()
	}
	
	private func updateLayerFrames() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / (7.0 / 3.0))
		trackLayer.setNeedsDisplay()
		if lowerThumbImageView.isHighlighted {
			lowerThumbImageView.frame = CGRect(origin: thumbOriginForValue(lowerValue, thumbSize: highlightedThumbSize),
											   size: CGSize(width: highlightedThumbSize, height: highlightedThumbSize))
		} else {
			lowerThumbImageView.frame = CGRect(origin: thumbOriginForValue(lowerValue, thumbSize: thumbSize),
											   size: CGSize(width: thumbSize, height: thumbSize))
		}
		if upperThumbImageView.isHighlighted {
			upperThumbImageView.frame = CGRect(origin: thumbOriginForValue(upperValue, thumbSize: highlightedThumbSize),
											   size: CGSize(width: highlightedThumbSize, height: highlightedThumbSize))
		} else {
			upperThumbImageView.frame = CGRect(origin: thumbOriginForValue(upperValue, thumbSize: thumbSize),
											   size: CGSize(width: thumbSize, height: thumbSize))
		}

		CATransaction.commit()
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
		
		if lowerThumbImageView.frame.contains(previousLocation) {
			lowerThumbImageView.isHighlighted = true
		} else if upperThumbImageView.frame.contains(previousLocation) {
			upperThumbImageView.isHighlighted = true
		}

		updateLayerFrames()
		return lowerThumbImageView.isHighlighted || upperThumbImageView.isHighlighted
	}
	
	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		let location = touch.location(in: self)
		
		if (maximumValue - minimumValue) <= 0.000000011 {
			return true
		}

		let deltaLocation = location.x - previousLocation.x
		let deltaValue = (maximumValue - minimumValue) * deltaLocation / bounds.width
		
		let thumbSizeToTrackRatio = thumbSize / bounds.width * (maximumValue - minimumValue)
		let upperBoundForLower = upperValue - thumbSizeToTrackRatio
		let lowerBoundForUpper = lowerValue + thumbSizeToTrackRatio

		previousLocation = location

		if !isPushEnabled && upperThumbImageView.isHighlighted {
			upperValue += deltaValue
			upperValue = boundValue(upperValue, toLowerValue: lowerBoundForUpper,
									upperValue: maximumValue)
		} else if !isPushEnabled && lowerThumbImageView.isHighlighted {
			lowerValue += deltaValue
			lowerValue = boundValue(lowerValue, toLowerValue: minimumValue,
									upperValue: upperBoundForLower)
		} else if isPushEnabled && upperThumbImageView.isHighlighted {
			upperValue += deltaValue
			if upperValue <= lowerBoundForUpper && lowerValue + deltaValue > minimumValue {
				lowerValue += deltaValue
			} else if upperValue >= maximumValue {
				upperValue = maximumValue
			} else if upperValue < lowerBoundForUpper {
				upperValue -= deltaValue
			}
		} else if isPushEnabled && lowerThumbImageView.isHighlighted {
			lowerValue += deltaValue
			if lowerValue >= upperBoundForLower && upperValue + deltaValue < maximumValue {
				upperValue += deltaValue
			} else if lowerValue <= minimumValue {
				lowerValue = minimumValue
			} else if lowerValue > upperBoundForLower {
				lowerValue -= deltaValue
			}
		}

		updateLayerFrames()

		sendActions(for: .valueChanged)
		return true
	}
	
	override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
		lowerThumbImageView.isHighlighted = false
		upperThumbImageView.isHighlighted = false
		updateLayerFrames()
	}
	
	private func boundValue(_ value: CGFloat, toLowerValue lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
		return min(max(value, lowerValue), upperValue)
	}
	
}
