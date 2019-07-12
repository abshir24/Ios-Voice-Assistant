//
//  ViewController.swift
//  Voice Assistant
//
//  Created by Abshir Mohamed on 7/11/19.
//  Copyright © 2019 Abshir Mohamed. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
    @IBOutlet weak var activateBtn: UIButton!
  
    @IBOutlet weak var textView: UITextView!
    private var speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier:"en-Us"))//1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang:String = "en-US"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activateBtn.isEnabled = false //2
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate//3
        speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization{ (authStatus) in //4
            var isButtonEnabled = false
            
            switch authStatus{//5
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            OperationQueue.main.addOperation(){
                self.activateBtn.isEnabled = isButtonEnabled
            }
        }
    }
    
    @IBAction func activateMic(_ sender: Any) {
        print("activateMic")
        speechRecognizer = SFSpeechRecognizer(locale:Locale.init(identifier:lang))
        
        if audioEngine.isRunning{
            audioEngine.stop()
            recognitionRequest?.endAudio()
            activateBtn.isEnabled = false
            activateBtn.setTitle("Start Recording", for: .normal)
        }else{
            startRecording()
            activateBtn.setTitle("Stop Recording", for: .normal)
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
                self.textView?.text = result?.bestTranscription.formattedString
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.activateBtn.isEnabled = true
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

