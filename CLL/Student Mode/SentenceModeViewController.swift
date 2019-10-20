import UIKit
import FlatUIKit
import AVKit
import IoniconsKit

final class SentenceModeViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var inputTextField: FUITextField!
    @IBOutlet weak var goButton: FUIButton!
    @IBOutlet weak var pauseResumeButton: FUIButton!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedStepper: UIStepper!
    
    private var sentence: String?
    private var currentlySpokenCharacterRange: NSRange!
    private var speakingSpeed: Float = AVSpeechUtteranceDefaultSpeechRate
    
    let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sentence Mode"
        view.backgroundColor = .backgroundGrey
        currentlySpokenCharacterRange = NSRange(location: 0, length: 0)
        
        setupTextField()
        setupButtons()
        collectionView!.register(CharacterView.self, forCellWithReuseIdentifier: "Cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        synthesizer.delegate = self
        
        speedStepper.minimumValue = Double(AVSpeechUtteranceMinimumSpeechRate)
        speedStepper.maximumValue = Double(AVSpeechUtteranceMaximumSpeechRate)
        speedStepper.stepValue = 0.05
        speedLabel.text = String(format: "Speed: %.2f", speakingSpeed)
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
    }

    private func setupButtons() {
        goButton.buttonColor = .primaryRed
        goButton.shadowColor = .black
        goButton.shadowHeight = 3.0
        goButton.cornerRadius = 6.0
        goButton.titleLabel?.font = .regularFont(ofSize: 20)
        goButton.setTitleColor(.white, for: .normal)
        
        pauseResumeButton.isHidden = true
        pauseResumeButton.buttonColor = .primaryRed
        pauseResumeButton.shadowColor = .black
        pauseResumeButton.shadowHeight = 3.0
        pauseResumeButton.cornerRadius = 6.0
        pauseResumeButton.setTitleColor(.white, for: .normal)
        pauseResumeButton.titleLabel?.font = .ionicon(of: 20)
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
    }
    
    private func speakSentence(_ sentence: String) {
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language:"zh-CN")
        utterance.rate = speakingSpeed
        synthesizer.speak(utterance)
    }
    
    private func generateContentView() {
        collectionView.reloadData()
    }
    
    private func didFinishSpeaking() {
        goButton.setTitle("Start", for: .normal)
        pauseResumeButton.isHidden = true
        currentlySpokenCharacterRange = NSRange(location: 0, length: 0)
        collectionView.reloadData()
    }
    
    // MARK: IBActions
    
    @IBAction private func goButtonTapped(_ sender: Any) {
        view.endEditing(true)
        
        guard !synthesizer.isSpeaking else {
            synthesizer.stopSpeaking(at: .immediate)
            didFinishSpeaking()
            return
        }
        
        pauseResumeButton.isHidden = false
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)

        goButton.setTitle("Stop", for: .normal)

        let trimmedSentence = inputTextField.text?.removeWhitespace()
        guard let trimmed = trimmedSentence else { return }
        speakSentence(trimmed)
        
        sentence = trimmed
        generateContentView()
    }
    
    @IBAction private func pauseResumeButtonTapped(_ sender: Any) {
        if synthesizer.isPaused {
            _ = synthesizer.continueSpeaking()
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        } else {
            synthesizer.pauseSpeaking(at: .immediate)
            pauseResumeButton.setTitle(.ionicon(with: .iosPlay), for: .normal)
        }
    }
    
    @IBAction private func stepperSpeedChanged(_ sender: UIStepper) {
        speakingSpeed = Float(sender.value)
        speedLabel.text = String(format: "Speed: %.2f", speakingSpeed)
    }
}

extension SentenceModeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension SentenceModeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 80)
    }
}

extension SentenceModeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sentence?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CharacterView
        if let sentence = sentence {
            
            cell.metadata = IndividualCharacterViewMetadata(isStressed: false, isLong: false, toneNumber: sentence.toneNumber(), character: sentence)
            if (NSLocationInRange(indexPath.row, currentlySpokenCharacterRange)) {
                cell.backgroundColor = .yellow
            } else {
                cell.backgroundColor = .clear
            }
            
        }
        return cell
    }
    
}

extension SentenceModeViewController: AVSpeechSynthesizerDelegate {
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
