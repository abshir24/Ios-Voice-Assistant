//
//  ViewController.swift
//  Voice Assistant
//
//  Created by Abshir Mohamed on 7/11/19.
//  Copyright © 2019 Abshir Mohamed. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    private var speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier:"en-Us"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang:String = "en-US"
    
    var confirmationEffect: AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Sound that plays when "Hey Victoria" is heard
        let audioFile = Bundle.main.path(forResource: "confirmationsound", ofType:".mp3")
        
        do{
            try confirmationEffect = AVAudioPlayer(contentsOf: URL(fileURLWithPath:audioFile!))
        }
        catch{
            print("File not found")
        }
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        
        //Activates mic so that it is listening throughout the whole app
       startRecording()
        
    }
    
    func startRecording() {
        print("Start Recording")
        
        //If the recognition is on, turn it off
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        //Make the AudioSession start recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        //Start the recognizion proccess
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            //if there is speech to recognize
            if result != nil {
                //print the recognized speech to the screen as a String
                self.textView?.text = result?.bestTranscription.formattedString
                let keyWord = "hey victoria"
                // currSpeechStr holds all speech input as a String.
                var currSpeechStr: String = (result?.bestTranscription.formattedString)!
                var keyWordUsed: Bool = currSpeechStr.lowercased().contains(keyWord)
                
                if (keyWordUsed) {
                    //This plays the chime sound when user calls on Victoria
                    self.confirmationEffect.play()
                    
                    self.audioEngine.stop()
                    
                    //Restarts audio engine
                    do {
                        try self.audioEngine.start()
                        
                    } catch {
                        print("audioEngine couldn't start because of an error.")
                    }
                    
                    currSpeechStr = (result?.bestTranscription.formattedString)!
                    
                    //If user asks to share image send to share view
                    if(currSpeechStr.lowercased().contains("share")){
                        self.audioEngine.stop()
                       self.performSegue(withIdentifier: "Share", sender: self)
                    }
                    //If user asks to comment on image goes to comment view
                    else if(currSpeechStr.lowercased().contains("comment"))
                    {
                        self.audioEngine.stop()
                        self.performSegue(withIdentifier: "Comment", sender: self)
                    }
                    
                    //self.textView?.text = nil // This part sets the String that holds all words in speech to empty.
                }
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView?.text = "Say something, I'm listening!"
    }
 
    
  
    
}

