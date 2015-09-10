//
//  ViewController.swift
//  SwiftVideoPlayer
//
//  Created by Benjamin Horner on 08/09/2015.
//  Copyright (c) 2015 Qanda. All rights reserved.
//

import UIKit
import SwiftVideoPlayer

class ViewController: UIViewController, VideoPlayerDelegate {
    
    
    var player: VideoPlayer!
    
    let videoURLString = "https://v.cdn.vine.co/r/videos/87DFC77702972658601489752064_1bdfc8e7016.3.1_5IH3bEUktlF4Q2jauHL0q3dPAXtmMAmsQJhJOZnIW.Cl9EPTgMj46EaM0c1PjHiO.mp4"
    
    let videoRect = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.width)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.player = VideoPlayer(frame: videoRect, parentView: self.view, file: videoURLString)
        
        self.player.delegate = self
        
        self.player.scrubberMaximumTrackTintColor = UIColor.clearColor()
        
        self.player.play()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: delegates
    func playerReady(player: VideoPlayer) {
        println("playerReady")
    }
    
    func playerPlaybackStateDidChange(player: VideoPlayer) {
        println("playerPlaybackStateDidChange")
    }
    
    func playerBufferingStateDidChange(player: VideoPlayer) {
        println("playerBufferingStateDidChange")
    }
    
    func playerPlaybackDidEnd(player: VideoPlayer) {
        println("playerPlaybackDidEnd")
    }
    
    func playerPlaybackWillStartFromBeginning(player: VideoPlayer) {
        println("playerPlaybackWillStartFromBeginning")
    }
    
    
    @IBAction func playPause(sender: UITapGestureRecognizer) {
        
        if self.player.playbackState == .Playing {
            
            self.player.pause()
            
        }
        
        else {
            
            self.player.play()
            
        }
        
    }
}

