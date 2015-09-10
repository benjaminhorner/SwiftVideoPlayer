# SwiftVideoPlayer
SwiftVideoPlayer is a lightweight drop-in class that simplifies the usage of AVPlayer.
It was inspired by the excellent https://github.com/piemonte/Player
Credits to https://github.com/piemonte

#INSTALLATION
Using cocoapds simply add the following to your podfile
``` pod 'SwiftVideoPlayer' ```

then run 
``` pod install ```

Don't forget to import SwiftVideoPlayer to your project
``` import SwiftVideoPlayer ```

# USAGE
1. include the VideoPlayerDelegate in your class
2. instanciate the player like so :

  ```self.player = VideoPlayer(frame: THE_VIDEO_CGRECT, parentView: THE_UIVIEW_TO_HOLD_THE_PLAYER, file: THE_VIDEO_URL_STRING)```
3. Set the delegate : `self.player.delegate = self`

# PARAMETERS (Optional)
- Scrubber parameters 

scrubberPositionX: CGFloat (default = 0)

scrubberPositionY: CGFloat (default = UIScreen.mainScreen().bounds.width - 2)

scrubberHeight: CGFloat (default = 4)

scrubberWidth: CGFloat = (default = UIScreen.mainScreen().bounds.width)

scrubberTintColor: UIColor (default = UIColor(red: 78.0/255, green: 184.0/255, blue: 87.0/255, alpha: 1.0) )

scrubberMaximumTrackTintColor: UIColor? // If you wish to "remove" it, set it to UIColor.clearColor()

minimalScrubber: Bool (default = true) // as is, the thumbImage is hidden. Set to false if you wish to have a thumb image

- Player parameters

hasScrubber: Bool (default = true) // Set it to false if you wish to remove the scrubber
playerBackgroundColor: UIColor (default = UIColor.blackColor())
playbackLoops: Bool (default = false)
playbackFreezesAtEnd: Bool (default = false)

# UPCOMING IMPROVEMENTS
- Possibility to change the thumb Image
- Show Current Time and Video Duration
- Possibility to enable/disable currentTime and duration visibility
- Customisable Play/Pause Buttons
