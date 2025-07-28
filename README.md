[![License](https://img.shields.io/github/license/youstanzr/YouTag)](LICENSE) [![Language](https://img.shields.io/badge/Swift-5-orange?logo=Swift&logoColor=white)](https://swift.org) 
## About
**Batta Player** (formerly *YouTag*) is a smart iOS music player that organizes your music library with custom tags, lyrics, and dynamic, mood-based playlists. Import songs from your device or iCloud, auto-extract metadata, and create instant playlists based on tags, artist, album, release year, or song duration.

![](/Images/screenshot_banner.png)

## Features
- Import MP3, MP4, and WAV files from device or iCloud
- Organizes and tags your local music library
- Auto-extract and edit song metadata
- Organize your music library with custom tags and lyrics
- Create smart playlists using tags, artist, album, year, or duration
- Dynamic mood-based playlists generated on the fly
- Plays music in the background
- Background playback with adjustable speed (0.75x / 1.25x)

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
**Batta Player** (formerly *YouTag*) is licensed under the GNU General Public License v3.0 with an additional trademark clause.  
You are free to use, modify, and contribute to the code, but you may not distribute or release a derivative app under a different name or branding without explicit permission.  

See the [LICENSE](LICENSE) file for full terms.