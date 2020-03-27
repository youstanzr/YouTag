//
//  SongDetailViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class SongDetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {

	var songDict: Dictionary<String, Any>!
	let LM = LibraryManager()
	var tagsView: YYTTagView!
	let dismissButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = GraphicColors.orange
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 32)
		btn.setTitle("✔︎", for: .normal)
		btn.contentVerticalAlignment = .top
		btn.titleEdgeInsets = UIEdgeInsets(top: 2.5, left: 0.0, bottom: 0.0, right: 0.0)
		return btn
	}()
	let thumbnailImageView = UIImageView()
	let titleTextField: UITextField = {
		let txtField = UITextField()
		txtField.backgroundColor = .clear
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtField.autocorrectionType = .no
		txtField.placeholder = "Title"
		txtField.addPadding(padding: .equalSpacing(5))
		txtField.returnKeyType = .done
		txtField.layer.cornerRadius = 5
		txtField.layer.borderWidth = 1.0
		txtField.layer.borderColor = UIColor.lightGray.cgColor
		return txtField
	}()
	var artistsTagsView: YYTTagView!
	let albumTextField: UITextField = {
		let txtField = UITextField()
		txtField.backgroundColor = .clear
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtField.autocorrectionType = .no
		txtField.placeholder = "Album"
		txtField.addPadding(padding: .equalSpacing(5))
		txtField.returnKeyType = .done
		txtField.layer.cornerRadius = 5
		txtField.layer.borderWidth = 1.0
		txtField.layer.borderColor = UIColor.lightGray.cgColor
		return txtField
	}()
	let releaseYrTextField: UITextField = {
		let txtField = UITextField()
		txtField.backgroundColor = .clear
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtField.autocorrectionType = .no
		txtField.placeholder = "Release Year"
		txtField.addPadding(padding: .equalSpacing(5))
		txtField.keyboardType = .numberPad
		txtField.returnKeyType = .done
		txtField.layer.cornerRadius = 5
		txtField.layer.borderWidth = 1.0
		txtField.layer.borderColor = UIColor.lightGray.cgColor
		return txtField
	}()
	let lyricsTextView: UITextView = {
		let txtView = UITextView()
		txtView.backgroundColor = .clear
		txtView.textAlignment = .left
		txtView.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtView.autocorrectionType = .no
		txtView.text = "Lyrics"
		txtView.textColor = GraphicColors.placeholderGray
		txtView.layer.cornerRadius = 5
		txtView.layer.borderWidth = 1.0
		txtView.layer.borderColor = UIColor.lightGray.cgColor
		return txtView
	}()

	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = GraphicColors.backgroundWhite

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

		let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
		
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songDict["id"] as! String).jpg"))
		thumbnailImageView.image = UIImage(data: imageData ?? Data())
        self.view.addSubview(thumbnailImageView)
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70).isActive = true
		thumbnailImageView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
		thumbnailImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0/3.0).isActive = true

		titleTextField.delegate = self
		titleTextField.text = songDict["title"] as? String
        self.view.addSubview(titleTextField)
		titleTextField.translatesAutoresizingMaskIntoConstraints = false
		titleTextField.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 15).isActive = true
		titleTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		titleTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		titleTextField.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true

		let artistsTags = NSMutableArray(array: songDict["artists"] as? NSArray ?? NSArray())
		artistsTagsView = YYTTagView(frame: .zero, tagsList: artistsTags, isAddEnabled: true, isMultiSelection: false, isDeleteEnabled: true)
		artistsTagsView.addTagPlaceHolder = "Artist"
		self.view.addSubview(artistsTagsView)
		artistsTagsView.translatesAutoresizingMaskIntoConstraints = false
		artistsTagsView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 10).isActive = true
		artistsTagsView.heightAnchor.constraint(equalToConstant: 44).isActive = true
		artistsTagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor).isActive = true
		artistsTagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor).isActive = true

		albumTextField.delegate = self
		albumTextField.text = songDict["album"] as? String
		self.view.addSubview(albumTextField)
		albumTextField.translatesAutoresizingMaskIntoConstraints = false
		albumTextField.topAnchor.constraint(equalTo: artistsTagsView.bottomAnchor, constant: 10).isActive = true
		albumTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		albumTextField.leadingAnchor.constraint(equalTo: artistsTagsView.leadingAnchor).isActive = true
		albumTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.65, constant: -2.5).isActive = true

		releaseYrTextField.delegate = self
		releaseYrTextField.text = songDict["releaseYear"] as? String
		self.view.addSubview(releaseYrTextField)
		releaseYrTextField.translatesAutoresizingMaskIntoConstraints = false
		releaseYrTextField.topAnchor.constraint(equalTo: albumTextField.topAnchor).isActive = true
		releaseYrTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		releaseYrTextField.leadingAnchor.constraint(equalTo: albumTextField.trailingAnchor, constant: 5).isActive = true
		releaseYrTextField.widthAnchor.constraint(equalTo: artistsTagsView.widthAnchor, multiplier: 0.35, constant: -2.5).isActive = true

		lyricsTextView.delegate = self
		if songDict["lyrics"] as! String != "" {
			lyricsTextView.text = songDict["lyrics"] as? String
			lyricsTextView.textColor = .black
		}
		self.view.addSubview(lyricsTextView)
		lyricsTextView.translatesAutoresizingMaskIntoConstraints = false
		lyricsTextView.topAnchor.constraint(equalTo: albumTextField.bottomAnchor, constant: 10).isActive = true
		lyricsTextView.heightAnchor.constraint(equalToConstant: 55).isActive = true
		lyricsTextView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor).isActive = true
		lyricsTextView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor).isActive = true

        dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        self.view.addSubview(dismissButton)
		dismissButton.translatesAutoresizingMaskIntoConstraints = false
		dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		dismissButton.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
		dismissButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.15, constant: -35).isActive = true
		dismissButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
		
		let songTags = NSMutableArray(array: songDict["tags"] as? NSArray ?? NSArray())
		tagsView = YYTTagView(frame: .zero, tagsList: songTags, isAddEnabled: true, isMultiSelection: false, isDeleteEnabled: true)
		tagsView.addTagPlaceHolder = "Tag"
		self.view.addSubview(tagsView)
		tagsView.translatesAutoresizingMaskIntoConstraints = false
		tagsView.topAnchor.constraint(equalTo: lyricsTextView.bottomAnchor, constant: 15).isActive = true
		tagsView.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -30).isActive = true
		tagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor).isActive = true
		tagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor).isActive = true
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func dismiss(sender: UIButton) {
		if releaseYrTextField.text!.isNumeric || releaseYrTextField.text == "" {
			self.updateSong()
			LM.updateSong(newSong: songDict)
			dismiss(animated: true, completion: nil)
		}
    }
    
    func updateSong() {
		songDict["title"] = titleTextField.text
		songDict["artists"] = artistsTagsView.tagsList
		songDict["album"] = albumTextField.text
		songDict["releaseYear"] = releaseYrTextField.text
		songDict["lyrics"] = lyricsTextView.text != "Lyrics" ? lyricsTextView.text : ""
		songDict["tags"] = tagsView.tagsList
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.text = textField.text!.capitalized
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if textView.textColor == GraphicColors.placeholderGray {
			textView.text = nil
			textView.textColor = UIColor.black
		}
	}

	func textViewDidEndEditing(_ textView: UITextView) {
		textView.contentOffset = .zero
		if textView.text == "" || textView.text.replacingOccurrences(of: "\n", with: "") == "" {
			textView.text = "Lyrics"
			textView.textColor = GraphicColors.placeholderGray
		}
	}
		
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let userInfo = notification.userInfo else {return}
		guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
		let keyboardFrame = keyboardSize.cgRectValue
		if self.view.frame.origin.y == 0 {
			self.view.frame.origin.y -= getMoveableDistance(keyboarHeight: keyboardFrame.height)
		}
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		if self.view.frame.origin.y != 0 {
			self.view.frame.origin.y = 0
		}
	}

	func getMoveableDistance(keyboarHeight: CGFloat) ->  CGFloat{
		var y:CGFloat = 0.0
		if let activeTF = getSelectedTextField() {
			var tfMaxY = activeTF.frame.maxY
			var containerView = activeTF.superview!
			while containerView.frame.maxY != self.view.frame.maxY {
				let contViewFrm = containerView.convert(activeTF.frame, to: containerView.superview)
				tfMaxY = tfMaxY + contViewFrm.minY
				containerView = containerView.superview!
			}
			let keyboardMinY = self.view.frame.height - keyboarHeight
			if tfMaxY + 10.0 > keyboardMinY {
				y = (tfMaxY - keyboardMinY) + 10.0
			}
		} else if let activeTV = getSelectedTextView() {
			var tvMaxY = activeTV.frame.maxY
			var containerView = activeTV.superview!
			while containerView.frame.maxY != self.view.frame.maxY {
				let contViewFrm = containerView.convert(activeTV.frame, to: containerView.superview)
				tvMaxY = tvMaxY + contViewFrm.minY
				containerView = containerView.superview!
			}
			let keyboardMinY = self.view.frame.height - keyboarHeight
			if tvMaxY + 10.0 > keyboardMinY {
				y = (tvMaxY - keyboardMinY) + 10.0
			}
		}
		return y
	}
	
}
