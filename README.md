[![License](https://img.shields.io/github/license/youstanzr/YouTag)](LICENSE) [![Language](https://img.shields.io/badge/Swift-5-orange?logo=Swift&logoColor=white)](https://swift.org) 
## About
**YouTag** is an iOS music player app that organizes your local music library with smart tags, lyrics, and mood-based playlists. You can enrich songs with artist, album, and custom tags, and the app automatically creates dynamic playlists based on your filters such as tags, artist, album, release year, or duration.

![](/Images/screenshot_banner.png)

## Features
- Supports mp4, mp3 and wav file types
- Organizes and tags your local music library
- Enrich songs with lyrics, artist, album, and custom tags
- Smart playlists based on filters and mood

- Auto extraction of song metadata information for mp3 and wav
- Customize playlist based on filters
- Plays music in the background
- Change song playback rate to x0.75 or x1.25


## Requirements
- Tested on Xcode 16.4 and later
- Tested on iOS 16.0 and later

## Installation
1. Clone/Download the repo.
2. Open `YouTag.xcodeproj` in Xcode.
3. Configure code signing.
4. Build & run!

If you are still having trouble, consider this [reference](https://help.apple.com/xcode/mac/current/#/dev5a825a1ca)

## Classes Architecture

- PlaylistManager
	- NowPlayingView
	- PlaylistLibraryView (*inherits* LibraryTableView)
		- LibraryCell
	- PlaylistFilters
- YYTAudioPlayer
- YYTRangeSlider
	- YYTRangeSliderTrackLayer
- YYTTagView / YYTFilterTagView
	- YYTTagCell
- LocalFileManager

## Contribution
- If you have a **feature request**, open an **issue**
- If you found a **bug**, open an **issue**
- If you want to **contribute**, submit a **pull request**

## Attribution
### Libraries
- HTTP networking: [Alamofire](https://github.com/Alamofire/Alamofire)
- UILabel scrolling animation: [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
- UITextfield suggestions: [SearchTextField](https://github.com/apasccon/SearchTextField)
### Resources
- YYTAudioPlayer based on: [Background Audio Player Sync Control Center](https://medium.com/@quangtqag/background-audio-player-sync-control-center-516243c2cdd1)
- YYTRangeSlider based on: [How To Make a Custom Control Tutorial: A Reusable Slider](https://www.raywenderlich.com/7595-how-to-make-a-custom-control-tutorial-a-reusable-slider)
### Graphics
- Album image: [@author](https://www.flaticon.com/authors/freepik)
- Artist image: [@author](https://www.flaticon.com/authors/freepik)
- Calendar image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Duration image: [@author](https://www.flaticon.com/authors/freepik)
- Filter image: [@author](https://www.flaticon.com/authors/freepik)
- Setting image: [@author](https://www.flaticon.com/authors/freepik)
- List image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Loop image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Music Note image: [@author](https://www.flaticon.com/authors/becris)
- Next image: [@author](https://www.flaticon.com/authors/smashicons)
- Pause image: [@author](https://www.flaticon.com/authors/kiranshastry)
- Play image: [@author](https://www.flaticon.com/authors/smashicons)
- Previous image: [@author](https://www.flaticon.com/authors/smashicons)
- Shuffle image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Tag image: [@author](https://www.flaticon.com/authors/those-icons)

## License
YouTag is licensed under the GNU General Public License v3.0 with an additional trademark clause.  
You are free to use, modify, and contribute to the code, but you may not distribute or release a derivative app under a different name or branding without explicit permission.  

See the [LICENSE](LICENSE) file for full terms.