//
//  ViewController.swift
//  Audio Mixer Demo
//
//  Created by ANDREW SMITH on 13/03/2015.
//  Copyright (c) 2015 Robot Loves You. All rights reserved.
//

import UIKit
import AVFoundation

/*
 
 https://freesound.org/people/tim.kahn/sounds/75064/

 https://stackoverflow.com/a/15360097/4833705

 > https://codeberg.org/soundtouch/soundtouch

 https://stackoverflow.com/questions/32294934/pitch-shifting-in-real-time-with-avaudioengine-using-swift

 https://github.com/AudioKit/AudioKit
 */

class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    var engine: AVAudioEngine!
    var playerA: AVAudioPlayerNode!
    var playerB: AVAudioPlayerNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        engine = AVAudioEngine()
        playerA = AVAudioPlayerNode()
        playerB = AVAudioPlayerNode()
        playerA.volume = 0.5
        playerB.volume = 0.5
        
        // Tsk tsk, automatically unwrapping optionals is bad form, but
        // this is just a demo so I'll let you off.
        // Here you are getting the path for the sound file you added to your project and converting it into a file url.
        guard let path = Bundle.main.path(forResource: "farah-faucet", ofType: "wav") else { return }
        let url = URL(fileURLWithPath: path)
        
        // Here you are creating an AVAudioFile from the sound file,
        // preparing a buffer of the correct format and length and loading
        // the file into the buffer.
        
        do {
            
            let file = try AVAudioFile(forReading: url)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return }
            
            do {
                
                try file.read(into: buffer)
                
                // This is a reverb with a cathedral preset. It's nice and ethereal
                // You're also setting the wetDryMix which controls the mix between the effect and the
                // original sound.
                let reverb = AVAudioUnitReverb()
                reverb.loadFactoryPreset(AVAudioUnitReverbPreset.cathedral)
                reverb.wetDryMix = 50
                
                // This is a distortion with a radio tower preset which works well for speech
                // As distortion tends to be quite loud you're setting the wetDryMix to only 25
                let distortion = AVAudioUnitDistortion()
                distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.speechRadioTower)
                distortion.wetDryMix = 25
                
                // Attach the four nodes to the audio engine
                engine.attach(playerA)
                engine.attach(playerB)
                engine.attach(reverb)
                engine.attach(distortion)
                
                // Connect playerA to the reverb
                engine.connect(playerA, to: reverb, format: buffer.format)
                
                // Connect the reverb to the mixer
                engine.connect(reverb, to: engine.mainMixerNode, format: buffer.format)
                
                // Connect playerB to the distortion
                engine.connect(playerB, to: distortion, format: buffer.format)
                
                // Connect the distortion to the mixer
                engine.connect(distortion, to: engine.mainMixerNode, format: buffer.format)
                
                // Schedule playerA and playerB to play the buffer on a loop
                playerA.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
                playerB.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
                
                // Start the audio engine
                engine.prepare()
                
            } catch {
                print(error.localizedDescription)
            }
            
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            try engine.start()
        } catch {
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func togglePlayPauseHidden() {
        pauseButton.isHidden = !pauseButton.isHidden
        playButton.isHidden = !playButton.isHidden
    }
    
    @IBAction func playButtonTapped(sender: UIButton) {
        print("tapped")
        playerA.play()
        playerB.play()
        togglePlayPauseHidden()
    }

    @IBAction func pauseButtonTapped(sender: UIButton) {
        playerA.pause()
        playerB.pause()
        togglePlayPauseHidden()
    }
    
    @IBAction func sliderChanged(sender: UISlider) {
        playerA.volume = sender.value
        playerB.volume = 1.0 - sender.value
    }
}

