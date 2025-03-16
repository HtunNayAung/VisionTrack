import SwiftUI
import AVFoundation

struct DestinationInputView: View {
    @State private var destinationText: String = ""
    @State private var isListening = false
    @State private var shouldListenAfterSpeech = true
    @State private var isNavigating = false
    @ObservedObject private var speechRecognizer = SpeechRecognizer()
    @FocusState private var isTextEditorFocused: Bool
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        self.speechSynthesizer.delegate = SpeechDelegate.shared
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    
                    TextEditor(text: $destinationText)
                        .frame(minHeight: 50, maxHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                        .font(.title2)
                        .foregroundColor(.black)
                        .lineSpacing(5)
                        .focused($isTextEditorFocused)
                        .onTapGesture {
                            isTextEditorFocused.toggle()
                        }
                    if destinationText.isEmpty && isTextEditorFocused == false{
                        Text("Enter destination or speak...")
                            .foregroundColor(.black)
                            .padding(.top, 15)
                            .padding(.leading, 20)
                            .font(.title2)
                    }
                }
                
                
                Spacer()
                
                VStack {
                    Text(isListening ? "Listening..." : "Tap to Speak")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .foregroundColor(.white)
                        .font(.system(size: 100, weight: .bold))
                }
                .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 7/8)
                .background(isListening ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                .onTapGesture {
                    handleMicButtonTap()
                }
                NavigationLink(destination: LiveMetalCameraView(), isActive: $isNavigating) {
                   EmptyView()
               }
            }
            .onAppear {
                speechRecognizer.requestPermission()
            }
            .onReceive(speechRecognizer.$recognizedText) { newValue in
                if isListening {
                    destinationText = newValue
                }
            }
            .onShake {
                confirmDestinationByShake()
            }
        }
    }

    private func handleMicButtonTap() {
        print("DEBUG: Mic button tapped")

        provideHapticFeedback()

        if !isListening {
            if speechSynthesizer.isSpeaking {
                print("DEBUG: Speech is already playing, waiting to finish.")
                return
            }
            print("DEBUG: Speaking 'Where would you like to go?'")
            shouldListenAfterSpeech = true
            speakText("Where would you like to go?")
        } else {
            print("DEBUG: Stopping mic listening")
            speechRecognizer.stopListening()
            isListening = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !self.destinationText.isEmpty {
                    self.shouldListenAfterSpeech = false
                    self.speakText("Destination is \(self.destinationText). Shake the phone to confirm.")
                }
            }
        }
    }

    private func provideHapticFeedback() {
        DispatchQueue.main.async {
            print("DEBUG: Haptic feedback triggered")
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
        }
    }
    
    private func confirmDestinationByShake() {
        if destinationText.isEmpty {
            print("DEBUG: No destination set, nothing to confirm.")
            return
        }

        let confirmationMessage = "Route is set. Get ready to move."
        print("DEBUG: Shake detected → \(confirmationMessage)")
        speakText(confirmationMessage)

        // ✅ Navigate to LiveMetalCameraView after speech output
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            DispatchQueue.main.async {
                print("DEBUG: Navigating to LiveMetalCameraView")
                self.isNavigating = true
            }
        }
    }

    private func speakText(_ text: String) {
        print("DEBUG: Speaking prompt - \(text)")

        // Stop any ongoing speech before starting new speech
        if speechSynthesizer.isSpeaking {
            print("DEBUG: Stopping current speech")
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        // Reset the audio session to allow speaking again
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("DEBUG: Audio session activated for speech")
        } catch {
            print("ERROR: Could not reset audio session - \(error.localizedDescription)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        speechSynthesizer.speak(utterance)
        print("DEBUG: Speech started, waiting to finish before listening...")

        SpeechDelegate.shared.onSpeechFinished = {
            DispatchQueue.main.async {
                print("DEBUG: Speech finished.")

                if self.shouldListenAfterSpeech {
                    print("DEBUG: Restarting mic for user input...")
                    self.isListening = true
                    self.speechRecognizer.startListening()
                } else {
                    print("DEBUG: Mic will NOT restart after confirmation speech.")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SpeechDelegate.shared.onSpeechFinished = nil
            }
        }
    }

}

//Singleton delegate to track speech completion
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechDelegate()
    var onSpeechFinished: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("DEBUG: Speech finished, triggering microphone...")
        DispatchQueue.main.async {
            self.onSpeechFinished?()
        }
    }
}
