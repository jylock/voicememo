//
//  CalendarTableCell.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 8/3/16.
//  Copyright © 2016 JYLock. All rights reserved.
//

import UIKit
import AVFoundation


class CalendarTableCell: UITableViewCell {
    
    
    // MARK: - Outlet
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    
    // MARK: - Properties
    var memo: Memo!
    
    // Recorder
    var audioRecorder:AVAudioRecorder!
    
    // Player
    var audioPlayer:AVAudioPlayer!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    var url: NSURL!

    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setUserInterfaceToPlayMode(true)
        
    }
    
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Setup functions
    func cellSetup() {
        loadContent()
        prepAudioPlayer()
    }
    
    // load audio file at view initialization
    private func loadContent() {
        titleLabel.text = memo.title
        noteLabel.text = memo.note
        dateLabel.text = String(memo.date!)
        
        // get audio file
        let filename = memo.audioFileName
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let pathArray = [dirPath, filename!]
        url =  NSURL.fileURLWithPathComponents(pathArray)
        
        print("--- title = \(memo.title)---")
        print("--- url = \(url) ---")
    }
    
    
    // MARK: - UI functions
    func setUserInterfaceToPlayMode(isPlayMode: Bool) {
        playButton.enabled = isPlayMode
        stopButton.enabled = !isPlayMode
    }
    
    
    
    // MARK: - Play audio
    func prepAudioPlayer() {
        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
        } catch let err as NSError{
            audioPlayer = nil
            print("audioPlayer initialization failed")
            print(err.localizedDescription)
        }
        audioPlayer.enableRate = true
        
        audioEngine = AVAudioEngine()
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch _ {
            audioFile = nil
        }
    }
    
    
    @IBAction func startPlayAudio(sender: UIButton) {
        // Update UI
        setUserInterfaceToPlayMode(false)
        
        
        // Play the sound
        playAudioWithVariablePitch(1.0)
        
    }
    
    @IBAction func stopPlayAudioAction(sender: UIButton) {
        // Update UI
        setUserInterfaceToPlayMode(true)
        stopPlayAudio()
    }
    
    func stopPlayAudio() {
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
    }
    
    func playAudioWithVariablePitch(pitch: Float){
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let changePitchEffect = AVAudioUnitTimePitch()
        changePitchEffect.pitch = pitch
        audioEngine.attachNode(changePitchEffect)
        
        audioEngine.connect(audioPlayerNode, to: changePitchEffect, format: nil)
        audioEngine.connect(changePitchEffect, to: audioEngine.outputNode, format: nil)
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil) {
            // When the audio completes, set the user interface on the main thread
            dispatch_async(dispatch_get_main_queue()) {self.setUserInterfaceToPlayMode(true) }
        }
        
        do {
            try audioEngine.start()
        } catch _ {
        }
        
        audioPlayerNode.play()
    }
    


}
