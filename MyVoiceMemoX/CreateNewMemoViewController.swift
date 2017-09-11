//
//  CreateNewMemoViewController.swift
//  MyVoiceMemoX
//
//  Created by Junyuan Suo on 7/26/16.
//  Copyright © 2016 JYLock. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class CreateNewMemoViewController: UIViewController, AVAudioRecorderDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var recordStartButton: UIButton!
    @IBOutlet weak var recordStopButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var memoTitle: UITextField!
    @IBOutlet weak var memoDescription: UITextView!
    
    
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var pitchSlider: UISlider!
    
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    
    // MARK: - Properties
    
    // Record and play session
    var session: AVAudioSession!
    
    // Recorder
    var audioRecorder:AVAudioRecorder!
    var memo:Memo!
    var fileName: String = "BlankAudioFile.wav"
    let blankAudioFileName = "BlankAudioFile.wav"
    
    
    // Player
    var audioPlayer:AVAudioPlayer!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    
    // Core data
    var managedObjectContext: NSManagedObjectContext? =
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext
    
    // Misc
    var memoSaved: Bool = false

    
    
    
    
    // MARK: View Cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        printFiles()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        memoSaved = false
        setUserInterfaceToRecordMode(true)
        prepAudioSession()
    }
    
    
    
    
    // MARK: - UI functions
    func setUserInterfaceToRecordMode(isRecordMode: Bool) {
        recordStartButton.hidden = !isRecordMode
        recordStopButton.hidden = isRecordMode
        playButton.enabled = false
        playButton.hidden = false
        stopButton.hidden = true
    }
    
    func setUserInterfaceToPlayMode(isPlayMode: Bool) {
        recordStartButton.hidden = false
        recordStartButton.enabled = isPlayMode
        recordStopButton.hidden = true
        playButton.hidden = !isPlayMode
        playButton.enabled = isPlayMode
        stopButton.hidden = isPlayMode
    }
    
    
    
    // MARK: - Recording functions
    
    func prepAudioSession() {
        // Setup audio session
        session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
    }
    
    @IBAction func startRecordAudio(sender: UIButton) {
        // User creates a new audio file, delete old one
        if !memoSaved && fileName != blankAudioFileName {
            deleteUnsavedAudioFile()
            print("---- User created new audio file ----")
        }
        
        
        // Update the UI
        setUserInterfaceToRecordMode(false)
        
        
        
        // Create a name for the file. This is the code that you are looking for
        fileName = "newMemo" + "_" + NSDate().description + ".wav"
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let pathArray = [dirPath, fileName]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        
        print("--- newFileNmae = \(fileName) ---")
        print("--- newFileURL = \(fileURL) ---")
        
        
        do {
            // Initialize and prepare the recorder
            audioRecorder = try AVAudioRecorder(URL: fileURL, settings: [String: AnyObject]())
        } catch _ {
        }
        audioRecorder.delegate = self
        audioRecorder.meteringEnabled = true;
        audioRecorder.prepareToRecord()
        
        audioRecorder.record()
    }
    
    
    
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if flag {
            // Prep for playing audio
            prepAudioPlayer()
            
        } else {
            print("Recording was not successful")
            setUserInterfaceToRecordMode(true)
        }
    }

    @IBAction func stopRecordAudio(sender: UIButton) {
        // Update UI
        setUserInterfaceToRecordMode(true)
        setUserInterfaceToPlayMode(true)
        
        audioRecorder.stop()
        do {
            try session.setActive(false)
        } catch _ {
        }
        
        // This function stops the audio. We will then wait to hear back from the recorder,
        // through the audioRecorderDidFinishRecording method
    }
    
    
    
    
    
    
    // MARK: - Playing functions
    func prepAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: audioRecorder.url)
        } catch _ {
            audioPlayer = nil
        }
        audioPlayer.enableRate = true
        
        audioEngine = AVAudioEngine()
        do {
            audioFile = try AVAudioFile(forReading: audioRecorder.url)
        } catch _ {
            audioFile = nil
        }
    }
    
    
    @IBAction func startPlayAudio(sender: UIButton) {
        // Update UI
        setUserInterfaceToPlayMode(false)
        
        // Get the pitch, rate from the slider
        let pitch: Float = pitchSlider.value
        let rate: Float = rateSlider.value
        
        // Play the sound
        playAudioWithVariablePitch(pitch, rate: rate)
        
        // Set the UI
        setUserInterfaceToPlayMode(false)
        
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
    
    
    
    // MARK: - Alert
    func doubleSaveAlert() {
        let alert = UIAlertController(title: "Warning", message: "You have already saved!", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func noAudioFileAlert() {
        let alert = UIAlertController(title: "Warning", message: "You did not record audio file. Can not save.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func saveSuccessfulAlert() {
        let alert = UIAlertController(title: "Saved", message: "New memo is saved!", preferredStyle: .Alert)

        let popVCAction = UIAlertAction(title: "Back to main list", style: .Default){(_) in
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        let stayAction = UIAlertAction(title: "Stay here", style: .Cancel, handler: nil)
        
        alert.addAction(popVCAction)
        alert.addAction(stayAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Save new memo
    @IBAction func saveNewMemo(sender: UIButton) {
        // prevent double save
        if memoSaved {
            
            // Pop alert
            doubleSaveAlert()
        }
        
        else {
            // if user did not create audio file
            if(fileName == blankAudioFileName) {
                noAudioFileAlert()
            }
            // user did create audio file, everything good
            else {
                memoSaved = true
                
                managedObjectContext?.performBlock {
                    self.memo = Memo(title: self.memoTitle.text!, note: self.memoDescription.text, audioFileName: self.fileName, context: self.managedObjectContext!)
                    // there is a method in AppDelegate
                    // which will save the context as well
                    // but we're just showing how to save and catch any error here
                    do {
                        try self.managedObjectContext?.save()
                    } catch let error {
                        print("Core Data Error: \(error)")
                    }
                }
                
                // Pop alert
                saveSuccessfulAlert()
                print("saved")
            }
            
        }
        
    }
    
    
    // Delete unsaved audio file
    func deleteUnsavedAudioFile() {
        let fileManager = NSFileManager.defaultManager()
        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        guard let dirPath = paths.first else {
            return
        }
        let filePath = "\(dirPath)/\(self.fileName)"
        do {
            try fileManager.removeItemAtPath(filePath)
            print("--- deletion successful ---")
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    
    
    // If an audio file is created, but the memo is not saved, delete audio file
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if parent == nil {
            // The back button was pressed or interactive gesture used
            if !memoSaved && fileName != blankAudioFileName {
                deleteUnsavedAudioFile()
                print("---- back clicked ----")
            }
        }
    }
    
    
    
    // MARK: - helper func
    
    // Change audio effects back to normal
    @IBAction func SetAudioSettingToDefault(sender: AnyObject) {
        pitchSlider.value = 1
        rateSlider.value = 1
    }
    

    func printFiles() {
        // Get the document directory url
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL( documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            // if you want to filter the directory contents you can do like this:
            //            let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            //            print("mp3 urls:",mp3Files)
            //            let mp3FileNames = mp3Files.flatMap({$0.URLByDeletingPathExtension?.lastPathComponent})
            //            print("mp3 list:", mp3FileNames)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
