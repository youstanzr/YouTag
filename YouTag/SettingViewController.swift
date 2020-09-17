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
	}
		
	@objc func dismiss(sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
}
