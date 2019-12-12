import UIKit
import FlatUIKit
import AVKit
import IoniconsKit

final class ParagraphModeViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var inputTextField: FUITextField!
    @IBOutlet private weak var recordButton: FUIButton!
    @IBOutlet private weak var pauseResumeButton: FUIButton!
    
    @IBOutlet private weak var shareButton: FUIButton!
    @IBOutlet private weak var playButton: FUIButton!
    
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private var audioFileName: URL!
    
    private var sentence: String?
    private var currentlySpokenCharacterRange: NSRange!
    
    private var timer = Timer()
    private var isPlaying = false
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Paragraph Mode"
        view.backgroundColor = .backgroundGrey
        currentlySpokenCharacterRange = NSRange(location: 0, length: 0)
        
        setupTextField()
        setupButtons()
        collectionView!.register(CharacterView.self, forCellWithReuseIdentifier: "Cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        requestRecordingAccess()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Initial Setup
    
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
    
    private func setupTextField() {
        inputTextField.font = .systemFont(ofSize: 20)
        inputTextField.backgroundColor = .white
        inputTextField.edgeInsets = UIEdgeInsets(top: 4, left: 15, bottom: 4, right: 15)
        inputTextField.textFieldColor = .white
        inputTextField.borderColor = .primaryRed
        inputTextField.borderWidth = 20
        inputTextField.cornerRadius = 3
        inputTextField.clipsToBounds = true
        inputTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }
    
    private func setupButtons() {
        for button in [recordButton, pauseResumeButton, playButton, shareButton] {
            button!.buttonColor = .primaryRed
            button!.shadowColor = .black
            button!.shadowHeight = 3.0
            button!.cornerRadius = 6.0
            button!.titleLabel?.font = .regularFont(ofSize: 20)
            button!.setTitleColor(.white, for: .normal)
        }

        pauseResumeButton.titleLabel?.font = .ionicon(of: 20)
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        
        recordButton.isEnabled = false
        pauseResumeButton.isHidden = true
        shareButton.isHidden = true
        playButton.isHidden = true
    }
    
    private func generateContentView() {
        collectionView.reloadData()
    }
    
    private func didFinishSpeaking() {
        timer.invalidate()
        finishRecording(success: true)
        updateButtons(forState: .notRecording)
        currentlySpokenCharacterRange = NSRange(location: 0, length: 0)
        collectionView.reloadData()
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
    
    enum StudentState {
        case recording
        case notRecording
    }
    
    private func updateButtons(forState state: StudentState) {
        switch state {
        case .recording:
            shareButton.isHidden = true
            playButton.isHidden = true
            playButton.isEnabled = true
            
            pauseResumeButton.isHidden = false
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        case .notRecording:
            recordButton.setTitle("Re-Record", for: .normal)
            pauseResumeButton.isHidden = true
            shareButton.isHidden = false
            playButton.isHidden = false
        }
    }
    
    @IBAction private func goButtonTapped(_ sender: Any) {
        dismissKeyboard()
        
        // STOP button tapped:
        guard audioRecorder == nil else {
            didFinishSpeaking()
            return
        }
        
        // Record button tapped:
        let trimmedSentence = inputTextField.text?.removeWhitespace()
        guard let trimmed = trimmedSentence else { return }
        sentence = trimmed
        
        generateContentView()
        updateButtons(forState: .recording)
        startTimer()
        startRecording()
    }
    
    @IBAction private func pauseResumeButtonTapped(_ sender: Any) {
        if audioRecorder.isRecording {
            audioRecorder.pause()
            pauseResumeButton.setTitle(.ionicon(with: .iosPlay), for: .normal)
            timer.invalidate()
        } else {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
            audioRecorder.record()
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        }
    }
    
    private func startTimer() {
        currentlySpokenCharacterRange = NSRange(location: 0, length: 1)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    }
    
    @objc private func timerLoop() {
        if currentlySpokenCharacterRange.location == sentence!.count {
            didFinishSpeaking()
        } else {
            currentlySpokenCharacterRange = NSRange(location: currentlySpokenCharacterRange.location + 1, length: 1)
            collectionView.reloadData()
        }
    }
    
    // MARK: - Playing back recorded audio
    
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
            isPlaying = false
        }
        else {
            if FileManager.default.fileExists(atPath: audioFileName.path) {
                playButton.isEnabled = false
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
    
    @IBAction private func shareButtonTapped(_ sender: Any) {
        guard let audioFile = audioFileName else { return }
        let activityVC = UIActivityViewController(activityItems: [audioFile], applicationActivities: nil)
        navigationController?.present(activityVC, animated: true, completion: nil)
    }
    
    
    // MARK: - Helpers
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc private func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else { return }
        recordButton.isEnabled = !text.removeWhitespace().isEmpty
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ParagraphModeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
}

extension ParagraphModeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 80)
    }
}

extension ParagraphModeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sentence?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CharacterView
        if let sentence = sentence {
            cell.metadata = IndividualCharacterViewMetadata(isStressed: false, isLong: false, toneNumber: sentence.toneNumber(), pinyin: sentence.transformToPinYin(), character: sentence)
            if (NSLocationInRange(indexPath.row, currentlySpokenCharacterRange)) {
                cell.backgroundColor = .yellow
            } else {
                cell.backgroundColor = .clear
            }
            
        }
        return cell
    }
}

/*
extension ParagraphModeViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        currentlySpokenCharacterRange = characterRange
        collectionView.reloadData()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeaking()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("speech did pause")
    }
}
 */

extension ParagraphModeViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension ParagraphModeViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.isEnabled = true
        recordButton.isEnabled = true
        isPlaying = false
    }
}
