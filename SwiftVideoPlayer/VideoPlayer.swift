//
//  VideoPlayer.swift
//  SwiftVideoPlayer
//
//  The MIT License (MIT)
//
//  Created by Benjamin Horner on 08/09/2015.
//  Copyright (c) 2015 Qanda. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


// TODO: Add delegates
// TODO: Add Buffer indicator
// TODO: Add Loader
// TODO: Add Network notifications (and delegates)

import UIKit
import AVFoundation
import Foundation
import CoreGraphics

public protocol VideoPlayerDelegate {
    
    func playerReady(player: VideoPlayer)
    func playerPlaybackStateDidChange(player: VideoPlayer)
    func playerBufferingStateDidChange(player: VideoPlayer)
    func playerPlaybackDidEnd(player: VideoPlayer)
    func playerPlaybackWillStartFromBeginning(player: VideoPlayer)
    
}

// ENUMS
public enum PlaybackState: Int, CustomStringConvertible {
    case Stopped = 0
    case Playing
    case Paused
    case Failed
    
    public var description: String {
        get {
            switch self {
            case Stopped:
                return "Stopped"
            case Playing:
                return "Playing"
            case Failed:
                return "Failed"
            case Paused:
                return "Paused"
            }
        }
    }
}

public enum BufferingState: Int, CustomStringConvertible {
    case Unknown = 0
    case Ready
    case Delayed
    
    public var description: String {
        get {
            switch self {
            case Unknown:
                return "Unknown"
            case Ready:
                return "Ready"
            case Delayed:
                return "Delayed"
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
// The Class
///////////////////////////////////////////////////////////////////////////////
public class VideoPlayer: NSObject {
    
    
    // Enums
    public var playbackState = PlaybackState.Stopped
    public var bufferingState = BufferingState.Unknown
    
    
    // Player
    private var player: AVPlayer!
    private var playerItem: AVPlayerItem!
    private var playerLayer: AVPlayerLayer!
    private var playerView: UIView!
    
    
    // Delegate
    public var delegate: VideoPlayerDelegate?
    
    
    // Scrubber
    private var scrubberUI: ScrubberSlider?
    public var scrubberPositionX: CGFloat = 0
    public var scrubberPositionY: CGFloat = UIScreen.mainScreen().bounds.width - 2
    public var scrubberHeight: CGFloat = 4
    public var scrubberWidth: CGFloat = UIScreen.mainScreen().bounds.width
    public var scrubberTintColor: UIColor = UIColor(red: 78.0/255, green: 184.0/255, blue: 87.0/255, alpha: 1.0)
    public var scrubberMaximumTrackTintColor: UIColor?
    public var minimalScrubber: Bool = true
    
    
    // Asset Data
    private var assetDuration: CMTime!
    
    
    // Parent View
    private var parentView: UIView!
    
    
    // Defaults
    public var hasScrubber: Bool = true
    public var playerBackgroundColor: UIColor = UIColor.blackColor()
    public var playbackLoops: Bool = false
    public var playbackFreezesAtEnd: Bool = false
    public var showBuffering: Bool = true
    public var bufferSize: CGFloat = 40
    public var bufferActivityIndicatorViewStyle: UIActivityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
    
    
    // Can Pan Slider
    private var canPan: Bool = false
    
    // Buffer
    private var buffer: UIActivityIndicatorView?
    
    
    // KVO contexts
    private var PlayerObserverContext = 0
    private var PlayerItemObserverContext = 0
    private var PlayerLayerObserverContext = 0
    
    // KVO player keys
    private let PlayerTracksKey = "tracks"
    private let PlayerPlayableKey = "playable"
    private let PlayerDurationKey = "duration"
    private let PlayerRateKey = "rate"
    
    // KVO player item keys
    private let PlayerStatusKey = "status"
    private let PlayerEmptyBufferKey = "playbackBufferEmpty"
    private let PlayerKeepUp = "playbackLikelyToKeepUp"
    
    // KVO player layer keys
    private let PlayerReadyForDisplay = "readyForDisplay"
    
    
    
    //************************************************************//
    // MARK: Initializer
    required public init(frame: CGRect, parentView: UIView, file: String) {
        
        // Call super initializer
        super.init()
        
        let sourceURL = NSURL(string: file)
        
        self.parentView = parentView
        
        self.setupAVPlayerItem(sourceURL!)
        
        self.setupAVPlayer()
        
        self.setupAVPlayerLayer(frame)
        
        
        // Create a UIView to hold the player
        // This is neccessary to use a UISlider as the Scrubber
        self.playerView = UIView(frame: frame)
        playerView.layer.addSublayer(self.playerLayer)
        
        // Add the view
        parentView.insertSubview(playerView, atIndex: 0)
        
        // Init the buffer
        self.initBuffer()
        
        // Add Observers
        self.addObservers()
        
        // Add Notifications
        self.addNotifications()
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Player actions (Play, Pause…)
    public func playFromBeginning() {
        
        self.delegate?.playerPlaybackWillStartFromBeginning(self)
        
        self.player.seekToTime(kCMTimeZero)
        self.play()
    }
    
    public func play() {
        self.player.play()
        self.playbackState = .Playing
        self.delegate?.playerPlaybackStateDidChange(self)
    }
    
    public func pause() {
        
        if self.playbackState != .Playing {
            return
        }
        
        self.player.pause()
        self.playbackState = .Stopped
        self.delegate?.playerPlaybackStateDidChange(self)
    }
    
    public func seekToTime(time: CMTime) {
        self.player.seekToTime(time, completionHandler: { (completed) -> Void in
            self.play()
            self.playbackState = .Playing
            self.delegate?.playerPlaybackStateDidChange(self)
        })
    }
    
    public func setToTime(time: CMTime) {
        self.player.seekToTime(time)
        self.pause()
    }
    
    public func stop() {
        if self.playbackState == .Stopped {
            return
        }
        
        self.player.pause()
        self.playbackState = .Stopped
        self.delegate?.playerPlaybackStateDidChange(self)
        self.delegate?.playerPlaybackDidEnd(self)
    }
    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Scrubber
    private func addScrubberLayer() {
        
        if self.scrubberUI == nil {
            
            // define the scrubber Frame
            self.scrubberUI = ScrubberSlider(frame: CGRectMake(self.scrubberPositionX, self.scrubberPositionY, self.scrubberWidth, self.scrubberHeight))
            
            // Remove the UISlider's rounded corners
            self.scrubberUI?.setMaximumTrackImage(self.imageWithColor(self.scrubberTintColor, frame: CGRectMake(0, 0, 1, self.scrubberHeight)), forState: UIControlState.Normal)
            self.scrubberUI?.setMinimumTrackImage(self.imageWithColor(self.scrubberTintColor, frame: CGRectMake(0, 0, 1, self.scrubberHeight)), forState: UIControlState.Normal)
            
            // pass the scrubber the defined height
            self.scrubberUI?.height = scrubberHeight
            
            // Scrubber min and max
            self.scrubberUI?.minimumValue = 0
            self.scrubberUI?.maximumValue = 100
            
            // remove thumb image
            // If the user has defined a minimal scrubber
            if minimalScrubber {
                self.scrubberUI?.setThumbImage(UIImage(), forState: UIControlState.Normal)
            }
            
            // Set the scrubber Color
            self.scrubberUI?.tintColor = self.scrubberTintColor
            
            // Set the scrubber BackgroundColor
            if (self.scrubberMaximumTrackTintColor != nil) {
                self.scrubberUI?.maximumTrackTintColor = self.scrubberMaximumTrackTintColor
            }
            
            // add it to the parentView
            self.parentView.insertSubview(self.scrubberUI!, aboveSubview: self.playerView)
            
            // Add scrubber listener (UIControlEventValueChanged on UISlider)
            self.scrubberUI?.addTarget(self, action: "pause", forControlEvents: UIControlEvents.TouchDown)
            
            // Add targets for touch up and touchout : play() the video again
            self.scrubberUI?.addTarget(self, action: "seekVideoByDragging:", forControlEvents: UIControlEvents.TouchUpInside)
            self.scrubberUI?.addTarget(self, action: "seekVideoByDragging:", forControlEvents: UIControlEvents.TouchUpOutside)
            
            // Add the periodic observer
            self.addPeriodicTimeObserver()
            
        }
        
    }
    
    // Scrubber Advancement
    private func addPeriodicTimeObserver() {
        
        let interval: CMTime = CMTimeMake(1, Int32(Double(NSEC_PER_SEC)))
        
        self.player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) { (CMTime) -> Void in
            self.updateScrubberWidth(CMTime)
        }
        
    }
    
    // Scrubber Update
    private func updateScrubberWidth(time: CMTime) {
        
        let duration: Float = Float(CMTimeGetSeconds(self.playerItem.duration))
        let normalizedCurrenTime: Float = Float(CMTimeGetSeconds(self.playerItem.currentTime()) * 100.0)
        
        
        if CMTimeCompare(time, kCMTimeZero) > -1 {
            
            let normalizedTime: Float =  normalizedCurrenTime / duration
            self.scrubberUI?.value = normalizedTime
            
        }
        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Seek Video By Dragging UISlider
    public func seekVideoByDragging(sender: ScrubberSlider) {
        
        if (self.canPan) {
            
            // Pause the player
            self.pause()
            
            // Get the slider value
            let width: CGFloat = CGFloat(sender.value)
            
            // Get Duration and calculate ratio (multiplier)
            let duration: CGFloat = CGFloat(CMTimeGetSeconds(self.playerItem.duration))
            let ratio = CGFloat(100) / duration
            
            let newTime: CGFloat = CGFloat(width) / ratio
            
            // Calculate time
            if !isnan(newTime) && !isinf(newTime) && (newTime > 0) && (newTime < duration) {
                
                let time: CMTime = CMTimeMakeWithSeconds(Float64(newTime), Int32(Double(NSEC_PER_SEC)))
                
                self.setToTime(time)
            }
            
        }
        
    }
    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: AVPlayer Item
    private func setupAVPlayerItem(url: NSURL) {
        
        self.playerItem = AVPlayerItem(URL: url)
        
    }
    
    // MARK: AVPlayer
    private func setupAVPlayer() {
        
        self.player = AVPlayer(playerItem: self.playerItem)
        
    }
    
    // MARK: AVPlayer Layer
    private func setupAVPlayerLayer(frame: CGRect) {
        
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.backgroundColor = self.playerBackgroundColor.CGColor
        self.playerLayer.fillMode = AVLayerVideoGravityResizeAspectFill
        self.playerLayer.frame = frame
        
    }
    
    // TODO: Replace Item
    // replaceCurrentItemWithPlayerItem
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: KVO
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch (keyPath, context) {
            
        case (PlayerRateKey?, &PlayerObserverContext):
            true
            
        case (PlayerStatusKey?, &PlayerItemObserverContext):
            true
            
        case (PlayerKeepUp?, &PlayerItemObserverContext):
            if let item = self.playerItem {
                self.bufferingState = .Ready
                self.delegate?.playerBufferingStateDidChange(self)
                self.playerBufferingStateDidChange()
                
                if item.playbackLikelyToKeepUp && self.playbackState == .Playing {
                    self.canPan = true
                    self.play()
                }
            }
            
            let status = (change?[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue
            
            
            switch (status) {
            case AVPlayerStatus.ReadyToPlay.rawValue:
                self.playerLayer.player = self.player
                self.playerLayer.hidden = false
                self.canPan = true
                
                // if the player should have a scrubber
                if self.hasScrubber {
                    self.addScrubberLayer()
                }
                
            case AVPlayerStatus.Failed.rawValue:
                self.playbackState = PlaybackState.Failed
                self.delegate?.playerPlaybackStateDidChange(self)
                
            default:
                true
            }
        case (PlayerEmptyBufferKey?, &PlayerItemObserverContext):
            if let item = self.playerItem {
                if item.playbackBufferEmpty {
                    self.bufferingState = .Delayed
                    self.delegate?.playerBufferingStateDidChange(self)
                    self.playerBufferingStateDidChange()
                }
            }
            
            let status = (change?[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue
            
            switch (status) {
            case AVPlayerStatus.ReadyToPlay.rawValue:
                
                self.playerLayer.player = self.player
                self.playerLayer.hidden = false
                self.canPan = true
                
                // if the player should have a scrubber
                if self.hasScrubber {
                    self.addScrubberLayer()
                }
                
            case AVPlayerStatus.Failed.rawValue:
                
                self.playbackState = PlaybackState.Failed
                self.delegate?.playerPlaybackStateDidChange(self)
                
            default:
                true
            }
            
        case (PlayerReadyForDisplay?, &PlayerLayerObserverContext):
            if self.playerLayer.readyForDisplay {
                
                self.canPan = true
                
                // if the player should have a scrubber
                if self.hasScrubber {
                    self.addScrubberLayer()
                }
                
                self.delegate?.playerReady(self)
                
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            
        }
        
        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Observers
    private func addObservers() {
        
        self.player.addObserver(self, forKeyPath: PlayerRateKey, options: ([NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]) , context: &PlayerObserverContext)
        
        self.playerLayer.addObserver(self, forKeyPath: PlayerReadyForDisplay, options: ([NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]), context: &PlayerLayerObserverContext)
        
        self.playerItem?.addObserver(self, forKeyPath: PlayerEmptyBufferKey, options: ([NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]), context: &PlayerItemObserverContext)
        
        self.playerItem?.addObserver(self, forKeyPath: PlayerKeepUp, options: ([NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]), context: &PlayerItemObserverContext)
        
        self.playerItem?.addObserver(self, forKeyPath: PlayerStatusKey, options: ([NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old]), context: &PlayerItemObserverContext)
        
    }
    
    
    private func removeObservers() {
        
        self.playerLayer.removeObserver(self, forKeyPath: PlayerReadyForDisplay, context: &PlayerLayerObserverContext)
        
        self.player.removeObserver(self, forKeyPath: PlayerRateKey, context: &PlayerObserverContext)
        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: NSNotifications
    public func playerItemDidPlayToEndTime(aNotification: NSNotification) {
        if self.playbackLoops.boolValue == true || self.playbackFreezesAtEnd.boolValue == true {
            self.player.seekToTime(kCMTimeZero)
        }
        
        if self.playbackLoops.boolValue == false {
            self.stop()
        }
    }
    
    public func playerItemFailedToPlayToEndTime(aNotification: NSNotification) {
        self.playbackState = .Failed
        self.delegate?.playerPlaybackStateDidChange(self)
    }
    
    public func applicationWillResignActive(aNotification: NSNotification) {
        if self.playbackState == .Playing {
            self.pause()
        }
    }
    
    public func applicationDidEnterBackground(aNotification: NSNotification) {
        if self.playbackState == .Playing {
            self.pause()
        }
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Notifications
    private func addNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemFailedToPlayToEndTime:", name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        
        // Application
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
        
    }
    
    private func removeNotifications() {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: self.playerItem)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Buffer
    
    private func initBuffer() {
        
        if self.showBuffering {
            
            let bufferFrame: CGRect = CGRectMake((self.playerView.frame.size.width - self.bufferSize) / 2, (self.playerView.frame.size.height - self.bufferSize) / 2, self.bufferSize, self.bufferSize)
            self.buffer = UIActivityIndicatorView(frame: bufferFrame)
            
            // Add it to the view
            self.parentView.insertSubview(self.buffer!, aboveSubview: self.playerView)
            
            // Set the style
            self.buffer?.activityIndicatorViewStyle = self.bufferActivityIndicatorViewStyle
            
            // Hide it when stopped
            self.buffer?.hidesWhenStopped = true
            
            // Animate it
            self.buffer?.startAnimating()
            
        }
        
    }
    
    private func playerBufferingStateDidChange() {
        
        if (self.bufferingState == .Delayed) {
            self.buffer?.startAnimating()
        }
        else if ( (self.bufferingState == .Unknown) || (self.bufferingState == .Ready) ) {
            self.buffer?.stopAnimating()
        }
        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // UIImage helper
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    private func imageWithColor(color: UIColor, frame: CGRect) -> UIImage{
        let rect = frame
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Deinit
    deinit {
        
        self.playerLayer = nil
        self.delegate = nil
        
        
        self.removeNotifications()
        self.removeObservers()
        
        self.player.pause()
        
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////

// Custom UISlider

//////////////////////////////////////////////////////////////////////////////////////////////

public class ScrubberSlider : UISlider
{
    
    public var height: CGFloat = 4.0
    
    override public func trackRectForBounds(bounds: CGRect) -> CGRect {
        //keeps original origin and width, changes height, you get the idea
        let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: self.height))
        super.trackRectForBounds(customBounds)
        return customBounds
    }
    
    //while we are here, why not change the image here as well? (bonus material)
    override public func awakeFromNib() {
        self.setThumbImage(UIImage(named: "customThumb"), forState: .Normal)
        super.awakeFromNib()
    }
}
