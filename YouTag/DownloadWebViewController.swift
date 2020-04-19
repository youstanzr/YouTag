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

class DownloadWebViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {

	weak var delegate: DownloadWebViewDelegate!
	let webView = WKWebView()
	let urlFieldView = UIView()
	let urlField: UITextField = {
		let txtField = UITextField()
		txtField.text = "https://www.youtube.com"
		txtField.backgroundColor = GraphicColors.backgroundWhite
		txtField.textAlignment = .left
		txtField.font = UIFont.init(name: "DINCondensed-Bold", size: 17)
		txtField.autocorrectionType = .no
		txtField.placeholder = "URL"
		txtField.addPadding(padding: .equalSpacing(10))
		txtField.returnKeyType = .go
		txtField.layer.cornerRadius = 5
		txtField.keyboardType = .URL
		txtField.clearButtonMode = .whileEditing
		return txtField
	}()
	let progressBar: UIProgressView = {
		let pBar = UIProgressView()
		pBar.tintColor = GraphicColors.orange
		return pBar
	}()
	let webToolbar = UIToolbar()
	

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = GraphicColors.backgroundWhite

		webToolbar.barStyle = .default
		webToolbar.isTranslucent = true
		webToolbar.tintColor = .black
		webToolbar.barTintColor = GraphicColors.gray
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

		urlFieldView.backgroundColor = GraphicColors.gray
		self.view.addSubview(urlFieldView)
		urlFieldView.translatesAutoresizingMaskIntoConstraints = false
		urlFieldView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
		urlFieldView.heightAnchor.constraint(equalToConstant: 80).isActive = true
		urlFieldView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		urlFieldView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

		urlField.delegate = self
		urlFieldView.addSubview(urlField)
		urlField.translatesAutoresizingMaskIntoConstraints = false
		urlField.topAnchor.constraint(equalTo: urlFieldView.topAnchor, constant: 40).isActive = true
		urlField.heightAnchor.constraint(equalToConstant: 34).isActive = true
		urlField.leadingAnchor.constraint(equalTo: urlFieldView.leadingAnchor, constant: 5).isActive = true
		urlField.trailingAnchor.constraint(equalTo: urlFieldView.trailingAnchor, constant: -5).isActive = true

		webView.navigationDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		webView.load(URLRequest(url: URL(string: urlField.text!)!))
		self.view.addSubview(webView)
		webView.translatesAutoresizingMaskIntoConstraints = false
		webView.topAnchor.constraint(equalTo: urlFieldView.bottomAnchor).isActive = true
		webView.bottomAnchor.constraint(equalTo: webToolbar.topAnchor).isActive = true
		webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
		
		self.view.addSubview(progressBar)
		progressBar.translatesAutoresizingMaskIntoConstraints = false
		progressBar.bottomAnchor.constraint(equalTo: urlFieldView.bottomAnchor).isActive = true
		progressBar.heightAnchor.constraint(equalToConstant: 2).isActive = true
		progressBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
		progressBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

		webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
		webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
		
		let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
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
		self.dismiss(animated: true, completion: nil)
		delegate?.retrievedVideoLink(videoLink: webView.url!.absoluteString)
	}
	
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		let alert = UIAlertController(title: "Error", message:  error.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .default,  handler: nil))
		present(alert, animated: true, completion: nil)
	}
		
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "estimatedProgress" {
			progressBar.progress = Float(webView.estimatedProgress)
			progressBar.isHidden = (webView.estimatedProgress == 1.0)
		} else if keyPath == "URL" {
			urlField.text = webView.url?.absoluteString
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		if let urlString = urlField.text {
			if urlString != webView.url?.absoluteString {
				webView.load(URLRequest(url: URL(string: urlString)!))
			}
		}
		return true
	}

}
