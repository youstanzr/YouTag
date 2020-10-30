//
//  SettingViewController.swift
//  YouTag
//
//  Created by Youstanzr on 9/17/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
	
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
	var exportBackupButton: UIButton = {
		let btn = UIButton()
		btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 22)
		btn.setTitleColor(.black, for: .normal)
		btn.setTitle("Export Backup", for: .normal)
		return btn
	}()
	var importBackupButton: UIButton = {
		let btn = UIButton()
		btn.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 22)
		btn.setTitleColor(.black, for: .normal)
		btn.setTitle("Import Backup", for: .normal)
		return btn
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = GraphicColors.backgroundWhite

		dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
		self.view.addSubview(dismissButton)
		dismissButton.translatesAutoresizingMaskIntoConstraints = false
		dismissButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		dismissButton.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
		dismissButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.15, constant: -35).isActive = true
		dismissButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
		
		exportBackupButton.addTarget(self, action: #selector(exportBackupButtonAction), for: .touchUpInside)
		self.view.addSubview(exportBackupButton)
		exportBackupButton.translatesAutoresizingMaskIntoConstraints = false
		exportBackupButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		exportBackupButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
		exportBackupButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.1).isActive = true
		exportBackupButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

		importBackupButton.addTarget(self, action: #selector(importBackupButtonAction), for: .touchUpInside)
		self.view.addSubview(importBackupButton)
		importBackupButton.translatesAutoresizingMaskIntoConstraints = false
		importBackupButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
		importBackupButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
		importBackupButton.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.1).isActive = true
		importBackupButton.topAnchor.constraint(equalTo: exportBackupButton.bottomAnchor, constant: 20).isActive = true
	}
		
	@objc func dismiss(sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
	@objc func exportBackupButtonAction(sender: UIButton) {
		UIPasteboard.general.string = LibraryManager.getBackupString()
		let alert = UIAlertController(title: "Backup Exported", message: "Backup string has been copied to your clipboard. Kindly paste your backup string into a safe place to be used later when needed\n\n Note: thumbnails are not included in the backup and will reset to default thumbnail when importing", preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:nil))
		self.present(alert, animated: true, completion: nil)
	}

	@objc func importBackupButtonAction(sender: UIButton) {
		var bkpStr = ""
		let alert = UIAlertController(title: "Import Backup", message: "Kindly click ok when the backup string is copied to your clipboard", preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:{ (UIAlertAction) in
			bkpStr = UIPasteboard.general.string ?? ""
			print(bkpStr)
		}))
		self.present(alert, animated: true, completion:nil)
	}
}
