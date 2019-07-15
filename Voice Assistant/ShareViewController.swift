//
//  ShareViewController.swift
//  Voice Assistant
//
//  Created by Abshir Mohamed on 7/13/19.
//  Copyright © 2019 Abshir Mohamed. All rights reserved.
//

import UIKit
import Speech

class ShareViewController: UIViewController {
   
    private var speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier:"en-Us"))//1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang:String = "en-US"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate//3
        speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier: lang))
        
        activateMic()
       
    }
    
    func activateMic() {
        print("activateMic Share")
        speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier:lang))
        
        if audioEngine.isRunning{
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }else{
            startRecording()
        }
    }
    
    func startRecording() {
        print("Start Recording")
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
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
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                let keyWord = "hey Victoria"
                // currSpeechStr holds all speech input as a String.
                let currSpeechStr: String = (result?.bestTranscription.formattedString)!
                let keyWordUsed: Bool = currSpeechStr.lowercased().contains(keyWord)
                
                if (keyWordUsed) {
                    
                    self.audioEngine.stop()
                    
                    self.performSegue(withIdentifier: "homeSeg", sender: self)
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
        
    }

}
