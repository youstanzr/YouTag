//
//  DownloadWebViewController.swift
//  YouTag
//
//  Created by Youstanzr Alqattan on 3/17/20.
//  Copyright © 2020 Youstanzr Alqattan. All rights reserved.
//

import UIKit
import WebKit

protocol DownloadWebViewDelegate: class {
	func retrievedVideoLink(videoLink: String)
}

class DownloadWebViewController: UIViewController {

	weak var delegate: DownloadWebViewDelegate!
	let webView = WKWebView()
	let webToolbar = UIToolbar()
	let startUrl = URL(string: "https://www.youtube.com")


	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)

		webToolbar.barStyle = .default
		webToolbar.isTranslucent = true
		webToolbar.tintColor = .black
		webToolbar.barTintColor = .lightGray
		let doneButton = UIBarButtonItem(title: "✔︎", style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissBtn))
		let downloadButton = UIBarButtonItem(title: "↓", style: UIBarButtonItem.Style.plain, target: self, action: #selector(downloadBtn))
		let prevButton = UIBarButtonItem(title: "◀︎", style: UIBarButtonItem.Style.plain, target: self, action: #selector(prevBtn))
		let nextButton = UIBarButtonItem(title: "▶︎", style: UIBarButtonItem.Style.plain, target: self, action: #selector(nextBtn))
		let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
		webToolbar.setItems([prevButton, space, nextButton, space, downloadButton, space, doneButton], animated: false)
		self.view.addSubview(webToolbar)
		webToolbar.translatesAutoresizingMaskIntoConstraints = false
		webToolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
		webToolbar.heightAnchor.constraint(equalToConstant: 44).isActive = true
		webToolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		webToolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

		webView.allowsBackForwardNavigationGestures = true
		webView.load(URLRequest(url: startUrl!))
		self.view.addSubview(webView)
		webView.translatesAutoresizingMaskIntoConstraints = false
		webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 34).isActive = true
		webView.bottomAnchor.constraint(equalTo: webToolbar.topAnchor).isActive = true
		webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
	}
	
	@objc func prevBtn(_ sender: UIBarButtonItem) {
		if webView.canGoBack {
			webView.goBack()
		}
	}
	
	@objc func nextBtn(_ sender: UIBarButtonItem) {
		if webView.canGoForward {
			webView.goForward()
		}
	}
	
	@objc func dismissBtn(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	@objc func downloadBtn(_ sender: UIBarButtonItem) {
		delegate?.retrievedVideoLink(videoLink: webView.url!.absoluteString)
		self.dismiss(animated: true, completion: nil)
	}
	
}
