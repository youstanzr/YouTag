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
    
    class func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var version: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var buildNumber: String? {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

}

// MARK: UIViewController
extension UIViewController {
    
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
        let total = Int(self.rounded())
        let seconds = total % 60
        let minutes = (total / 60) % 60
        let hours = total / 3600

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
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
    
    // Helper to map Arabic/Persian digits to Latin
    var latinDigits: String {
        var out = String()
        out.reserveCapacity(self.count)
        for scalar in self.unicodeScalars {
            let v = scalar.value
            // Arabic-Indic 0-9: U+0660...U+0669
            if 0x0660...0x0669 ~= v {
                let mapped = UnicodeScalar(0x0030 + (v - 0x0660))!
                out.unicodeScalars.append(mapped)
                continue
            }
            // Extended Arabic-Indic (Persian) 0-9: U+06F0...U+06F9
            if 0x06F0...0x06F9 ~= v {
                let mapped = UnicodeScalar(0x0030 + (v - 0x06F0))!
                out.unicodeScalars.append(mapped)
                continue
            }
            out.unicodeScalars.append(scalar)
        }
        return out
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


// MARK: UIDevice
extension UIDevice {
    static var isLandscape: Bool {
        // Use size classes instead of raw interface orientation
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return false }
        let traits = scene.traitCollection
        if traits.verticalSizeClass != .unspecified {
            // Treat landscape as compact vertical space
            return traits.verticalSizeClass == .compact
        }
        // Fallback (rare): if size class is unspecified, defer to orientation
        return scene.interfaceOrientation.isLandscape
    }

    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Shared bottom bar sizing
extension UIButton {
    @discardableResult
    func applyStandardBottomBarHeight(_ height: CGFloat = 80) -> NSLayoutConstraint {
        // Required so other proportional constraints won't override it
        let c = heightAnchor.constraint(equalToConstant: height)
        c.priority = .required
        c.isActive = true
        return c
    }
}
