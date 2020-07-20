//
//  PlaylistLibraryView.swift
//  YouTag
//
//  Created by Youstanzr on 2/29/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import UIKit

protocol PlaylistLibraryViewDelegate: class {
	func didSelectSong(songDict: Dictionary<String, Any>)
}

class PlaylistLibraryView: LibraryTableView {

	weak var PLDelegate: PlaylistLibraryViewDelegate?
	
	var playlistArray = NSMutableArray()
	private struct LongPressPersistentValues {
		static var indexPath: IndexPath?
		static var cellSnapShot: UIView?
	}

	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		playlistArray = LM.libraryArray
		let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(gestureRecognizer:)))
		longpress.minimumPressDuration = 0.3
		self.addGestureRecognizer(longpress)
    }
	
	override func refreshTableView() {
		self.reloadData()
	}
		
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return playlistArray.count-1
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryCell", for: indexPath as IndexPath) as! LibraryCell

		let songDict = playlistArray.object(at: (playlistArray.count - 2 - indexPath.row) % playlistArray.count) as! Dictionary<String, Any>
		cell.songDict = songDict
		cell.refreshCell()
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as! LibraryCell

		print("Selected cell number \(indexPath.row) -> \(cell.songDict["title"] ?? "")")

		playlistArray.insert(playlistArray.lastObject!, at: 0)
		playlistArray.removeLastObject()
		playlistArray.remove(cell.songDict)
		playlistArray.add(cell.songDict)
		
		tableView.deselectRow(at: indexPath, animated: false)
		tableView.reloadData()
		
		PLDelegate?.didSelectSong(songDict: cell.songDict)
    }
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			playlistArray.removeObject(at: (playlistArray.count - 2 - indexPath.row) % playlistArray.count)
			tableView.reloadData()
		}
	}

	// MARK: Long pressing gesture to rearrange cells
	@objc func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {

		let longpress = gestureRecognizer as! UILongPressGestureRecognizer
		let state = longpress.state
		var locationInView = longpress.location(in: self)

		if (locationInView.y - self.contentOffset.y < 0) {
			locationInView.y = self.contentOffset.y
		} else if (locationInView.y - self.contentOffset.y > self.frame.height) {
			locationInView.y = self.contentOffset.y + self.frame.height
		}

		guard let indexPath = self.indexPathForRow(at: locationInView) else { return }

		switch state {
			case .began:
				LongPressPersistentValues.indexPath = indexPath
				let cell = self.cellForRow(at: indexPath) as! LibraryCell
				LongPressPersistentValues.cellSnapShot = cell.snapshotOfView()
				var center = cell.center
				LongPressPersistentValues.cellSnapShot?.center = center
				LongPressPersistentValues.cellSnapShot?.alpha = 0.0
				self.addSubview(LongPressPersistentValues.cellSnapShot!)

				UIView.animate(withDuration: 0.25, animations: {
					center.y = locationInView.y
					LongPressPersistentValues.cellSnapShot?.center = center
					LongPressPersistentValues.cellSnapShot?.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
					LongPressPersistentValues.cellSnapShot?.alpha = 0.98
					cell.alpha = 0.0
				}, completion: { (finished) -> Void in
					if finished {
						cell.isHidden = true
					}
				})

			case .changed:
				var center = LongPressPersistentValues.cellSnapShot?.center
				center?.y = locationInView.y
				LongPressPersistentValues.cellSnapShot?.center = center!
//				print(self.contentOffset.y ,locationInView.y, self.frame.height)
//				print(indexPath.row as Any, self.indexPathForRow(at: center!)?.row as Any)

				if (indexPath != LongPressPersistentValues.indexPath) {

//					//AutoScroll
//					if (locationInView.y - self.contentOffset.y < self.frame.height*0.2 && indexPath.row > 1) {
//
//						print("move up")
////						var p = self.contentOffset
////						p.y -= (self.cellForRow(at: self.indexPathsForVisibleRows![1])?.frame.height)!
////						self.setContentOffset(p, animated: true)
//						var indexP = indexPath
//						indexP.row -= 1
//						self.scrollToRow(at: indexPath, at: .top, animated: true)
//					}
//					else if (locationInView.y - self.contentOffset.y > self.frame.height*0.8 && indexPath.row < playlistArray.count) {
//
//						print("move down")
////						var p = self.contentOffset
////						p.y += (self.cellForRow(at: self.indexPathsForVisibleRows!.last!)?.frame.height)!
////						self.setContentOffset(p, animated: true)
//						var indexP = indexPath
//						indexP.row += 1
//						self.scrollToRow(at: indexPath, at: .bottom, animated: true)
//					}

					playlistArray.exchangeObject(at: playlistArray.count-indexPath.row-2, withObjectAt: playlistArray.count-(LongPressPersistentValues.indexPath?.row)!-2)
					self.moveRow(at: LongPressPersistentValues.indexPath!, to: self.indexPathForRow(at: center!)!)

					LongPressPersistentValues.indexPath = indexPath
			}

			default:
				let cell = self.cellForRow(at: LongPressPersistentValues.indexPath!) as! LibraryCell
				cell.isHidden = false
				cell.alpha = 0.0
				UIView.animate(withDuration: 0.25, animations: {
					LongPressPersistentValues.cellSnapShot?.center = cell.center
					LongPressPersistentValues.cellSnapShot?.transform = .identity
					LongPressPersistentValues.cellSnapShot?.alpha = 0.0
					cell.alpha = 1.0
				}, completion: { (finished) -> Void in
					if finished {
						LongPressPersistentValues.indexPath = nil
						LongPressPersistentValues.cellSnapShot?.removeFromSuperview()
						LongPressPersistentValues.cellSnapShot = nil
					}
				})
		}
	}

}
