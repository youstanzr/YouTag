[![License](https://img.shields.io/github/license/youstanzr/YouTag)](LICENSE) [![Language](https://img.shields.io/badge/Swift-5-orange?logo=Swift&logoColor=white)](https://swift.org) 

## About
**YouTag** is an iOS YouTube downloader that extracts the audio of any video and creates a local library for your songs. The app curate a playlist based on user's choice of filters. Filters can be on tags, artist, album, release year or duration.

## Requirements
- Tested on Xcode 11.0 and later
- Tested on iOS 13.0 and later

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
- YouTube URL extractor: [XCDYouTubeKit](https://github.com/0xced/XCDYouTubeKit)
### Resources
- YYTAudioPlayer based on: [Background Audio Player Sync Control Center](https://medium.com/@quangtqag/background-audio-player-sync-control-center-516243c2cdd1)
- YYTRangeSlider based on: [How To Make a Custom Control Tutorial: A Reusable Slider](https://www.raywenderlich.com/7595-how-to-make-a-custom-control-tutorial-a-reusable-slider)
### Graphics
- Album image: [@author](https://www.flaticon.com/authors/freepik)
- Artist image: [@author](https://www.flaticon.com/authors/freepik)
- Calendar image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Duration image: [@author](https://www.flaticon.com/authors/freepik)
- Filter image: [@author](https://www.flaticon.com/authors/freepik)
- List image: [@author](https://www.flaticon.com/authors/pixel-perfect)
- Next image: [@author](https://www.flaticon.com/authors/smashicons)
- Pause image: [@author](https://www.flaticon.com/authors/kiranshastry)
- Play image: [@author](https://www.flaticon.com/authors/smashicons)
- Previous image: [@author](https://www.flaticon.com/authors/smashicons)
- Tag image: [@author](https://www.flaticon.com/authors/those-icons)

## License
YouTag is available under the MIT license and provide its entire source code for free. You can use any part of my code in your app, if you choose. However, **attribution is greatly appreciated!**

See the [LICENSE](LICENSE) file for more information. 
