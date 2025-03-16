//
//  SpeechRecognizer.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//
import AVFoundation
import Speech
class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""  // ✅ Add this line

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status != .authorized {
                print("Speech recognition permission denied")
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied")
            }
        }
    }

    func startListening() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognition is not available")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        if recordingFormat.sampleRate == 0 || recordingFormat.channelCount == 0 {
            print("ERROR: Invalid audio format")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("ERROR: Could not start audio engine: \(error.localizedDescription)")
            return
        }

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString  // ✅ Now updates UI
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}


//import AVFoundation
//import Speech
//
//class SpeechRecognizer: ObservableObject {
//    private let audioEngine = AVAudioEngine()
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let speechRecognizer = SFSpeechRecognizer()
//
//    func requestPermission() {
//        SFSpeechRecognizer.requestAuthorization { status in
//            if status != .authorized {
//                print("Speech recognition permission denied")
//            }
//        }
//
//        AVAudioSession.sharedInstance().requestRecordPermission { granted in
//            if !granted {
//                print("Microphone permission denied")
//            }
//        }
//    }
//
//    func startListening(completion: @escaping (String) -> Void) {
//        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
//            print("Speech recognition is not available")
//            return
//        }
//        
//
//        // ✅ Ensure session is properly configured
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("Audio session configuration error: \(error.localizedDescription)")
//            return
//        }
//
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        recognitionRequest?.shouldReportPartialResults = true
//
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//
//        // ✅ Ensure valid format
//        if recordingFormat.sampleRate == 0 || recordingFormat.channelCount == 0 {
//            print("ERROR: Invalid audio format (sample rate or channel count is zero)")
//            return
//        }
//
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
//            self.recognitionRequest?.append(buffer)
//        }
//
//        do {
//            try audioEngine.start()
//        } catch {
//            print("ERROR: Could not start audio engine: \(error.localizedDescription)")
//            return
//        }
//
//        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
//            if let result = result {
//                completion(result.bestTranscription.formattedString)
//            }
//            if error != nil || (result?.isFinal ?? false) {
//                self.stopListening()
//            }
//        }
//    }
//
//    func stopListening() {
//        print("DEBUG: Stopping speech recognition")
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        recognitionRequest?.endAudio()
//        recognitionTask?.cancel()
//        recognitionRequest = nil
//        recognitionTask = nil
//    }
//}
