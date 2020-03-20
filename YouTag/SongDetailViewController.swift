//
//  SongDetailViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 2/28/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit

class SongDetailViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
	var songDict: Dictionary<String, Any>!
	let LM = LibraryManager()
	var tagsView: YTTagView!
	let dismissButton: UIButton = {
		let btn = UIButton()
		btn.backgroundColor = UIColor(red: 0.984, green: 0.588, blue: 0.188, alpha: 1.0)
		btn.titleLabel?.textColor = .white
		btn.titleLabel?.font = .boldSystemFont(ofSize: 32)
		btn.setTitle("✔︎", for: .normal)
		btn.contentVerticalAlignment = .top
		btn.titleEdgeInsets = UIEdgeInsets(top: -3.5, left: 0.0, bottom: 0.0, right: 0.0)
		return btn
	}()
	let thumbnailImageView = UIImageView()
	let titleTextField: UITextField = {
		let txtField = UITextField()
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtField.clearButtonMode = UITextField.ViewMode.whileEditing
		txtField.enablesReturnKeyAutomatically = true
		txtField.placeholder = "Song Title"
		txtField.addPadding(padding: .equalSpacing(5))
		txtField.returnKeyType = .done
		txtField.layer.cornerRadius = 5
		txtField.layer.borderWidth = 1.0
		txtField.layer.borderColor = UIColor.lightGray.cgColor
		return txtField
	}()
	let artistTextField: UITextField = {
		let txtField = UITextField()
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 16)
		txtField.clearButtonMode = UITextField.ViewMode.whileEditing
		txtField.enablesReturnKeyAutomatically = true
		txtField.placeholder = "Artist Name"
		txtField.addPadding(padding: .equalSpacing(5))
		txtField.returnKeyType = .done
		txtField.layer.cornerRadius = 5
		txtField.layer.borderWidth = 1.0
		txtField.layer.borderColor = UIColor.lightGray.cgColor
		return txtField
	}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)

		let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
		
		let imageData = try? Data(contentsOf: LocalFilesManager.getLocalFileURL(withNameAndExtension: "\(songDict["songID"] as! String).jpg"))
		thumbnailImageView.image = UIImage(data: imageData ?? Data())
        self.view.addSubview(thumbnailImageView)
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailImageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70).isActive = true
		thumbnailImageView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
		thumbnailImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 4.0/3.0).isActive = true

		titleTextField.delegate = self
		titleTextField.text = songDict["songTitle"] as? String
        self.view.addSubview(titleTextField)
		titleTextField.translatesAutoresizingMaskIntoConstraints = false
		titleTextField.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 15).isActive = true
		titleTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		titleTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		titleTextField.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true

		artistTextField.delegate = self
		artistTextField.text = songDict["artistName"] as? String
        self.view.addSubview(artistTextField)
		artistTextField.translatesAutoresizingMaskIntoConstraints = false
		artistTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 10).isActive = true
		artistTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		artistTextField.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor).isActive = true
		artistTextField.widthAnchor.constraint(equalTo: titleTextField.widthAnchor).isActive = true

        dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        self.view.addSubview(dismissButton)
		dismissButton.translatesAutoresizingMaskIntoConstraints = false
		dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		dismissButton.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
		dismissButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.15, constant: -35).isActive = true
		dismissButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

		
		let songTags = NSMutableArray(array: songDict["songTags"] as? NSArray ?? NSArray())
		tagsView = YTTagView(frame: .zero, tagsList: songTags, isAddable: true, isMultiSelection: false)
		self.view.addSubview(tagsView)
		tagsView.translatesAutoresizingMaskIntoConstraints = false
		tagsView.topAnchor.constraint(equalTo: artistTextField.bottomAnchor, constant: 15).isActive = true
		tagsView.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -30).isActive = true
		tagsView.centerXAnchor.constraint(equalTo: titleTextField.centerXAnchor).isActive = true
		tagsView.widthAnchor.constraint(equalTo: titleTextField.widthAnchor).isActive = true
    }

	@objc func dismiss(sender: UIButton) {
        self.updateSong()
        LM.updateSong(newSong: songDict)
        dismiss(animated: true, completion: nil)
    }
    
    func updateSong() {
		songDict["songTitle"] = titleTextField.text
		songDict["artistName"] = artistTextField.text
		songDict["songTags"] = tagsView.tagsList
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
