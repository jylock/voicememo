//
//  SavedMemoViewController.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 7/27/16.
//  Copyright © 2016 JYLock. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class SavedMemoViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var memoTitle: UITextField!
    @IBOutlet weak var memoDate: UILabel!
    @IBOutlet weak var memoDescription: UITextView!
    
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var pitchSlider: UISlider!
    
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    
    // MARK: - Properties
    
    // Recorder
    var audioRecorder:AVAudioRecorder!
    var memo:Memo!
    
    // Player
    var audioPlayer:AVAudioPlayer!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    var url: NSURL!

    // Core data
    var fetchedResultsController : NSFetchedResultsController!
    var indexPath: NSIndexPath!
    
    
    
    // MARK: - View Cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        setUserInterfaceToPlayMode(true)
        loadContent()
        prepAudioPlayer()
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
        
        // Get the pitch from the slider
        let pitch: Float = pitchSlider.value
        let rate: Float = rateSlider.value
        
        // Play the sound
        playAudioWithVariablePitch(pitch, rate: rate)
        
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
    
    func playAudioWithVariablePitch(pitch: Float, rate: Float){
        stopPlayAudio()
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let mixer = audioEngine.mainMixerNode
        
        let auTimePitch = AVAudioUnitTimePitch()
        
        auTimePitch.pitch = pitch // In cents. The default value is 1.0. The range of values is -2400 to 2400
        auTimePitch.rate = rate //The default value is 1.0. The range of supported values is 1/32 to 32.0.
        
        audioEngine.attachNode(auTimePitch)
        
        audioEngine.connect(audioPlayerNode, to: auTimePitch, format: mixer.outputFormatForBus(0))
        audioEngine.connect(auTimePitch, to: mixer, format: mixer.outputFormatForBus(0))
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil) {
            // When the audio completes, set the user interface on the main thread
            dispatch_async(dispatch_get_main_queue()) {
                self.setUserInterfaceToPlayMode(true)
            }
        }
        
        do {
            try audioEngine.start()
        } catch _ {
        }
        
        audioPlayerNode.play()
    }

    
    
    // MARK: Helper functions
    // Change audio effects back to normal
    @IBAction func SetAudioSettingToDefault(sender: AnyObject) {
        pitchSlider.value = 1
        rateSlider.value = 1
    }
    
    // load audio file at view initialization
    private func loadContent() {
        let memo = fetchedResultsController?.objectAtIndexPath(indexPath) as! Memo
        memoTitle.text = memo.title
        memoDescription.text = memo.note
        memoDate.text = String(memo.date!)
        
        // get audio file
        let filename = memo.audioFileName
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let pathArray = [dirPath, filename!]
        url =  NSURL.fileURLWithPathComponents(pathArray)
        
//        print("--- title = \(memo.title)---")
//        print("--- url = \(url) ---")
    }
    
    
    // MARK: - Delete memo
    // Delete Current Memo, pop VC
    @IBAction func deleteMemo(sender: AnyObject) {
        if let context = fetchedResultsController?.managedObjectContext,
            memo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Memo {
            
            // delete audio file first, then remove obj from core data
            memo.removeAudioFile()
            context.deleteObject(memo)
            
            do {
                try context.save()
            } catch let error {
                print("Core Data Error: \(error)")
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - Update Memo
    // Update current memo
    @IBAction func updateMemo(sender: AnyObject) {
        if let context = fetchedResultsController?.managedObjectContext,
            memo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Memo {
            
            // delete audio file first, then remove obj from core data
            memo.title = memoTitle.text
            memo.note = memoDescription.text
            
            do {
                try context.save()
            } catch let error {
                print("Core Data Error: \(error)")
            }
            
            
            // Pop alert
            updateSuccessfulAlert()
        }
    }
    
    
    // MARK: - Alert
    func updateSuccessfulAlert() {
        let alert = UIAlertController(title: "Edit Successful", message: "Changes saved!", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
