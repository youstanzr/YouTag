//
//  Extensions.swift
//  YouTag
//
//  Created by Youstanzr on 2/28/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

// MARK: UIApplication
extension UIApplication {
	
    class func getCurrentViewController(base: UIViewController? = {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }()) -> UIViewController? {

		if let nav = base as? UINavigationController {
			return getCurrentViewController(base: nav.visibleViewController)
			
		} else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
			return getCurrentViewController(base: selected)
			
		} else if let presented = base?.presentedViewController {
			return getCurrentViewController(base: presented)
		}
		return base
	}
	
	var version: String? {
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
	}

	var buildNumber: String? {
		return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
	}

}

// MARK: UIViewController
var spinner_view: UIView?
var progress_view: UIView?

extension UIViewController {
 
	func showSpinner(onView : UIView, withTitle title: String?) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = GraphicColors.alpha50Gray

        let ai = UIActivityIndicatorView(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
		let titleLbl = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width*0.65, height: 40))
		titleLbl.text = title ?? ""
		titleLbl.textColor = GraphicColors.backgroundWhite
		titleLbl.font = UIFont.init(name: "DINCondensed-Bold", size: 34)
		titleLbl.textAlignment = .center
		titleLbl.center = ai.center
		titleLbl.frame = CGRect(x: titleLbl.frame.minX, y: titleLbl.frame.minY - ai.frame.height - 10,
								width: titleLbl.frame.width, height: titleLbl.frame.height)

        DispatchQueue.main.async {
			spinnerView.addSubview(titleLbl)
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        spinner_view = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            spinner_view?.removeFromSuperview()
            spinner_view = nil
        }
    }
	
	func showProgressView(onView : UIView, withTitle title: String?) {
		let progressView = UIView.init(frame: onView.bounds)
        progressView.backgroundColor = GraphicColors.alpha50Gray
		
		let boxView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width*0.65, height: 80))
		boxView.backgroundColor = GraphicColors.backgroundWhite
		boxView.layer.cornerRadius = 10.0
		boxView.layer.borderWidth = 2.0
		boxView.layer.borderColor = GraphicColors.orange.cgColor
		boxView.center = progressView.center

		let pBar = UIProgressView(frame: CGRect(x: boxView.frame.width*0.1, y: boxView.frame.height * 0.8, width: boxView.frame.width*0.8, height: 2))
		pBar.tag = 10
		pBar.progressTintColor = GraphicColors.orange
		pBar.progress = 0.0
		
		let titleLbl = UILabel(frame: CGRect(x: 0, y: 0, width: pBar.frame.width, height: pBar.frame.minY - 10))
		titleLbl.text = title ?? ""
		titleLbl.font = UIFont.init(name: "DINCondensed-Bold", size: 30)
		titleLbl.textAlignment = .center
		titleLbl.center = pBar.center
		titleLbl.frame = CGRect(x: titleLbl.frame.minX, y: 5,
								width: titleLbl.frame.width, height: titleLbl.frame.height)

		
		DispatchQueue.main.async {
			boxView.addSubview(titleLbl)
			boxView.addSubview(pBar)
			progressView.addSubview(boxView)
			onView.addSubview(progressView)
		}
		
		progress_view = progressView
	}

	func updateProgressView(to value: Double) {
		DispatchQueue.main.async {
			(progress_view?.viewWithTag(10) as! UIProgressView).progress = Float(value)
		}
	}

	func removeProgressView() {
		DispatchQueue.main.async {
			progress_view?.removeFromSuperview()
			progress_view = nil
		}
	}

	
	func getSelectedTextField() -> UITextField? {
		let totalTextFields = getTextFieldsInView(view: self.view)
		
		for textField in totalTextFields {
			if textField.isFirstResponder {
				return textField
			}
		}
		return nil
	}
	
	func getTextFieldsInView(view: UIView) -> [UITextField] {
		var totalTextFields = [UITextField]()
		
		for subview in view.subviews as [UIView] {
			if let textField = subview as? UITextField {
				totalTextFields += [textField]
			} else {
				totalTextFields += getTextFieldsInView(view: subview)
			}
		}
		return totalTextFields
	}
	
	func getSelectedTextView() -> UITextView? {
		let totalTextViews = getTextViewsInView(view: self.view)
		
		for textView in totalTextViews {
			if textView.isFirstResponder {
				return textView
			}
		}
		return nil
	}
	
	func getTextViewsInView(view: UIView) -> [UITextView] {
		var totalTextViews = [UITextView]()
		
		for subview in view.subviews as [UIView] {
			if let textView = subview as? UITextView {
				totalTextViews += [textView]
			} else {
				totalTextViews += getTextViewsInView(view: subview)
			}
		}
		return totalTextViews
	}

}

// MARK: UIView
extension UIView {

	enum BorderSide {
		case top, bottom, left, right
	}
	
	func addBorder(side: BorderSide, color: UIColor, width: CGFloat) {
		let border = UIView()
		border.translatesAutoresizingMaskIntoConstraints = false
		border.backgroundColor = color
		self.addSubview(border)
		
		let topConstraint = topAnchor.constraint(equalTo: border.topAnchor)
		let rightConstraint = trailingAnchor.constraint(equalTo: border.trailingAnchor)
		let bottomConstraint = bottomAnchor.constraint(equalTo: border.bottomAnchor)
		let leftConstraint = leadingAnchor.constraint(equalTo: border.leadingAnchor)
		let heightConstraint = border.heightAnchor.constraint(equalToConstant: width)
		let widthConstraint = border.widthAnchor.constraint(equalToConstant: width)
		
		
		switch side {
			case .top:
				NSLayoutConstraint.activate([leftConstraint, topConstraint, rightConstraint, heightConstraint])
			case .right:
				NSLayoutConstraint.activate([topConstraint, rightConstraint, bottomConstraint, widthConstraint])
			case .bottom:
				NSLayoutConstraint.activate([rightConstraint, bottomConstraint, leftConstraint, heightConstraint])
			case .left:
				NSLayoutConstraint.activate([bottomConstraint, leftConstraint, topConstraint, widthConstraint])
		}
	}
	
	func snapshotOfView() -> UIView {
		
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
		self.layer.render(in: UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		let viewSnapshot : UIView = UIImageView(image: image)
		viewSnapshot.layer.masksToBounds = false
		viewSnapshot.layer.cornerRadius = 0.0
		viewSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
		viewSnapshot.layer.shadowRadius = 5.0
		viewSnapshot.layer.shadowOpacity = 0.4
		return viewSnapshot
	}

}

// MARK: UITableView
extension UITableView {
	
	func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
		return indexPath.section < numberOfSections && indexPath.row < numberOfRows(inSection: indexPath.section)
	}
	
	func scrollToTop(_ animated: Bool = false) {
		let indexPath = IndexPath(row: 0, section: 0)
		if hasRowAtIndexPath(indexPath: indexPath) {
			scrollToRow(at: indexPath, at: .top, animated: animated)
		}
	}
	
}


extension CGRect {
    
    /// SwifterSwift: Create a `CGRect` instance with center and size
    /// - Parameters:
    ///   - center: center of the new rect
    ///   - size: size of the new rect
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(x: center.x - size.width / 2.0, y: center.y - size.height / 2.0)
        self.init(origin: origin, size: size)
    }
    
}



// MARK: TimeInterval
extension TimeInterval {

	func stringFromTimeInterval() -> String {
		
		let time = NSInteger(self)
		let seconds = time % 60
		var minutes = (time / 60) % 60
		minutes += Int(time / 3600) * 60  // to account for the hours as minutes
		
		return String(format: "%0.2d:%0.2d",minutes,seconds)
	}
	
}

// MARK: AVAsset
extension AVAsset {

	// Provide a URL for where you wish to write
    // the audio file if successful
    func writeAudioTrack(to url: URL,
                         success: @escaping () -> (),
                         failure: @escaping (Error) -> ()) {
        Task {
            do {
                let asset = try await audioAsset()
                asset.write(to: url, success: success, failure: failure)
            } catch {
                failure(error)
            }
        }
    }

    private func write(to url: URL,
                       success: @escaping () -> (),
                       failure: @escaping (Error) -> ()) {
        // Create an export session that will output an
        // audio track (M4A file)
        guard let exportSession = AVAssetExportSession(asset: self,
                                                       presetName: AVAssetExportPresetAppleM4A) else {
                                                        // This is just a generic error
                                                        let error = NSError(domain: "domain",
                                                                            code: 0,
                                                                            userInfo: nil)
                                                        failure(error)

                                                        return
        }

        exportSession.outputFileType = .m4a
        exportSession.outputURL = url

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success()
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            @unknown default:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            }
        }
    }

    private func audioAsset() async throws -> AVAsset {
        // Create a new container to hold the audio track
        let composition = AVMutableComposition()
        // Load audio tracks asynchronously
        let audioTracks = try await loadTracks(withMediaType: .audio)

        // Iterate through the audio tracks while
        // Adding them to a new AVAsset
        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                               preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                // Load the timeRange property asynchronously
                let range = try await track.load(.timeRange)
                // Add the current audio track at the beginning of
                // the asset for the duration of the source AVAsset
                try compositionTrack?.insertTimeRange(range,
                                                      of: track,
                                                      at: range.start)
            } catch {
                throw error
            }
        }
        return composition
    }
	
}


// MARK: UITextField
extension UITextField {

	enum PaddingSpace {
		case left(CGFloat)
		case right(CGFloat)
		case equalSpacing(CGFloat)
	}
	
	func addPadding(padding: PaddingSpace) {
		
		self.leftViewMode = .always
		self.layer.masksToBounds = true
		
		switch padding {
			
			case .left(let spacing):
				let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
				self.leftView = leftPaddingView
				self.rightViewMode = .always
			
			case .right(let spacing):
				let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
				self.rightView = rightPaddingView
				self.rightViewMode = .always
			
			case .equalSpacing(let spacing):
				let equalPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
				// left
				self.leftView = equalPaddingView
				self.leftViewMode = .always
				// right
				self.rightView = equalPaddingView
				self.rightViewMode = .always
		}
	}
	
}

// MARK: String
extension NSString {

	func estimateSizeWidth(font: UIFont, padding: CGFloat) -> CGFloat {
		let size = CGSize(width: 200, height: 1000) // temporary size
		let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		let rect = self.boundingRect(with: size,
									options: options,
									attributes: [.font: font],
									context: nil)
		return ceil(rect.width) + padding
	}
	
}

extension String {

	var length: Int {
		return count
	}

	var isNumeric : Bool {
		return Double(self) != nil
	}
	
	var isRTL: Bool {
		if self == "" {
			return false
		}
		let tagschemes = NSArray(objects: NSLinguisticTagScheme.language)
		let tagger = NSLinguisticTagger(tagSchemes: tagschemes as! [NSLinguisticTagScheme], options: 0)
		tagger.string = self
		
		let language = tagger.tag(at: 0, scheme: NSLinguisticTagScheme.language, tokenRange: nil, sentenceRange: nil)
		return String(describing: language).range(of: "he") != nil ||
			String(describing: language).range(of: "ar") != nil ||
			String(describing: language).range(of: "fa") != nil
	}

	func trim() -> String {
		return self.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	subscript (i: Int) -> String {
		return self[i ..< i + 1]
	}
	
	func substring(fromIndex: Int) -> String {
		return self[min(fromIndex, length) ..< length]
	}
	
	func substring(toIndex: Int) -> String {
		return self[0 ..< max(0, toIndex)]
	}
	
	subscript (r: Range<Int>) -> String {
		let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
											upper: min(length, max(0, r.upperBound))))
		let start = index(startIndex, offsetBy: range.lowerBound)
		let end = index(start, offsetBy: range.upperBound - range.lowerBound)
		return String(self[start ..< end])
	}

	func convertToTimeInterval() -> TimeInterval {
		guard self != "" else {
			return 0
		}
		
		var interval:Double = 0
		
		let parts = self.components(separatedBy: ":")
		for (index, part) in parts.reversed().enumerated() {
			interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
		}
		
		return interval
	}
	
}

// MARK: NSArray
extension NSArray {

	func isSubset(of arr: NSArray) -> Bool{
		for i in 0 ..< self.count {
			if !arr.contains(self.object(at: i)) {
				return false
			}
		}
		return true
	}
	
	func hasIntersect(with arr: NSArray) -> Bool {
		for i in 0 ..< self.count {
			if arr.contains(self.object(at: i)) {
				return true
			}
		}
		return false
	}

}

// MARK: NSMutableArray
extension NSMutableArray {

	func sortAscending() -> NSMutableArray {
		return NSMutableArray(array: (self as AnyObject as! [String]).sorted {
			$0.localizedCompare($1) == ComparisonResult.orderedAscending
		})
	}
}
