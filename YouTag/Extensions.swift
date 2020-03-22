//
//  Extensions.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

var spinner_view : UIView?
 
// MARK: UIViewController
extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
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
extension UIView{
	enum BorderSide {
		case top, bottom, left, right
	}
	
	func getCurrentViewController() -> UIViewController? {
		if let rootController = UIApplication.shared.keyWindow?.rootViewController {
			var currentController: UIViewController! = rootController
			while( currentController.presentedViewController != nil ) {
				currentController = currentController.presentedViewController
			}
			return currentController
		}
		return nil
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
}

// MARK: TimeInterval
extension TimeInterval{
	func stringFromTimeInterval() -> String {
		
		let time = NSInteger(self)
		let seconds = time % 60
		let minutes = (time / 60) % 60
		
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
        do {
            let asset = try audioAsset()
            asset.write(to: url, success: success, failure: failure)
        } catch {
            failure(error)
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

    private func audioAsset() throws -> AVAsset {
        // Create a new container to hold the audio track
        let composition = AVMutableComposition()
        // Create an array of audio tracks in the given asset
        // Typically, there is only one
        let audioTracks = tracks(withMediaType: .audio)

        // Iterate through the audio tracks while
        // Adding them to a new AVAsset
        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                               preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                // Add the current audio track at the beginning of
                // the asset for the duration of the source AVAsset
                try compositionTrack?.insertTimeRange(track.timeRange,
                                                      of: track,
                                                      at: track.timeRange.start)
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
	func estimateSizeWidth(font: UIFont, padding: CGFloat) -> CGFloat{
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
	
	var isNumeric : Bool {
		return Double(self) != nil
	}
}

// MARK: NSArray
extension NSArray {
	func isSubset(arr: NSArray) -> Bool{
		for i in 0 ..< self.count {
			if !arr.contains(self.object(at: i)) {
				return false
			}
		}
		return true
	}
}
