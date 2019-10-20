import UIKit
import AVKit
import FlatUIKit

class AuthorRecordingViewController: UIViewController {

    var metadata: LessonMetadata? {
        didSet {
            refreshTranscript()
        }
    }

    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private var audioFileName: URL!
    
    @IBOutlet weak var pauseResumeButton: FUIButton!
    @IBOutlet weak var playButton: FUIButton!
    @IBOutlet weak var recordButton: FUIButton!
    @IBOutlet weak var continueButton: FUIButton!
    
    @IBOutlet weak var transcriptTextView: UITextView!
    
    private var isPlaying = false
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGrey
        title = "Record your Lesson"
        requestRecordingAccess()
        setupButtons()
    }
    
    private func refreshTranscript() {
        loadViewIfNeeded()
        transcriptTextView.layer.cornerRadius = 5
        transcriptTextView.flashScrollIndicators()
        transcriptTextView.text = metadata?.transcript.joined(separator: "\n")
    }
    
    private func setupButtons() {
        for button in [recordButton, pauseResumeButton, playButton, continueButton] {
            button!.buttonColor = .primaryRed
            button!.shadowColor = .black
            button!.shadowHeight = 3.0
            button!.cornerRadius = 6.0
            button!.titleLabel?.font = .regularFont(ofSize: 20)
            button!.setTitleColor(.white, for: .normal)
        }
        
        pauseResumeButton.titleLabel?.font = .ionicon(of: 20)
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        
        recordButton.isEnabled = true
        pauseResumeButton.isHidden = true
        playButton.isHidden = true
        continueButton.isHidden = true
    }
    
    private func didFinishSpeaking() {
        finishRecording(success: true)
        updateButtons(forState: .notRecording)
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        
        if isPlaying {
            audioPlayer.stop()
            finishListening()
        }
        
        let annotationVC = storyboard?.instantiateViewController(withIdentifier: "AuthorAnnotationViewController") as! AuthorAnnotationViewController
        navigationController?.pushViewController(annotationVC, animated: true)
        annotationVC.metadata = metadata
        annotationVC.audioFileUrl = audioFileName
    }
    
    // MARK: - Speech Recording
    
    private func startRecording() {
        let filename = String(Int.random(in: 0 ..< 1000000))
        audioFileName = getDocumentsDirectory().appendingPathComponent("\(filename).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setTitle("Stop", for: .normal)
        } catch {
            print("Error starting recording session")
        }
    }
    
    private func finishRecording(success: Bool) {
        print("Recording finished with success: \(success)")
        audioRecorder.stop()
        audioRecorder = nil
    }
    
    private func finishListening() {
        playButton.isEnabled = true
        continueButton.isEnabled = true
        recordButton.isEnabled = true
        isPlaying = false
    }
    
    enum StudentState {
        case recording
        case notRecording
    }
    
    private func updateButtons(forState state: StudentState) {
        switch state {
        case .recording:
            playButton.isHidden = true
            playButton.isEnabled = true
            continueButton.isHidden = true
            
            pauseResumeButton.isHidden = false
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        case .notRecording:
            recordButton.setTitle("Re-Record", for: .normal)
            pauseResumeButton.isHidden = true
            playButton.isHidden = false
            continueButton.isHidden = false
        }
    }
    
    @IBAction private func goButtonTapped(_ sender: Any) {
        // STOP button tapped:
        guard audioRecorder == nil else {
            didFinishSpeaking()
            return
        }
        
        // Record button tapped:
        updateButtons(forState: .recording)
        startRecording()
    }
    
    @IBAction private func pauseResumeButtonTapped(_ sender: Any) {
        if audioRecorder.isRecording {
            audioRecorder.pause()
            pauseResumeButton.setTitle(.ionicon(with: .iosPlay), for: .normal)
        } else {
            audioRecorder.record()
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        }
    }
    
    private func requestRecordingAccess() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [weak self] allowed in
                guard let this = self else { return }
                DispatchQueue.main.async {
                    if !allowed {
                        this.recordButton.isEnabled = false
                        print("Failed to grant microphone recording permission!")
                    }
                }
            }
        } catch {
            print("Failed to configure audio recording session!")
        }
    }
    
    private func prepareForAudioPlayback() {
        
        guard FileManager.default.fileExists(atPath: audioFileName.path) else {
            print("This file should exist!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileName)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch {
            print("Unable to initialize AVAudioPlayer with contents of \(String(describing: audioFileName))")
        }
    }
    
    @IBAction private func playButtonTapped(_ sender: Any) {
        if isPlaying {
            // TODO: This will never get hit b/c we're disabling the button during playback.
            audioPlayer.stop()
            playButton.isEnabled = true
            continueButton.isHidden = true
            isPlaying = false
        }
        else {
            if FileManager.default.fileExists(atPath: audioFileName.path) {
                playButton.isEnabled = false
                continueButton.isHidden = false
                recordButton.isEnabled = false
                prepareForAudioPlayback()
                audioPlayer.play()
                isPlaying = true
            }
            else {
                print("Audio file is missing!")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}

extension AuthorRecordingViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension AuthorRecordingViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishListening()
    }
}

extension FileManager {
    func getDocumentsDirectory() -> URL {
        let paths = urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
