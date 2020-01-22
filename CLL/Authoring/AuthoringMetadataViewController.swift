import UIKit
import JVFloatLabeledTextField
import FlatUIKit
import AVFoundation
import Speech

typealias Paragraph = String

struct LessonMetadata {
    let title: String
    let author: String
    let transcript: [Paragraph]
    
    func isValid() -> Bool {
        return !(title.isEmpty || author.isEmpty || transcript.isEmpty)
    }
}

class AuthoringMetadataViewController: UIViewController {

    @IBOutlet weak var lessonTitleField: JVFloatLabeledTextField!
    @IBOutlet weak var authorField: JVFloatLabeledTextField!
    @IBOutlet weak var transcriptTextView: UITextView!
    @IBOutlet weak var continueButton: FUIButton!
    @IBOutlet weak var speechBtn: FUIButton!
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var preSpeechText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create New Lesson"
        view.backgroundColor = .backgroundGrey
        continueButton.layer.shadowColor = UIColor.darkGray.cgColor
        setupButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            speechBtn.setTitle("Speech", for: .normal)
        }
    }

    private func setupButtons() {
        for button in [continueButton, speechBtn] {
            button!.buttonColor = .primaryRed
            button!.shadowColor = .black
            button!.shadowHeight = 3.0
            button!.cornerRadius = 6.0
            button!.titleLabel?.font = .regularFont(ofSize: 20)
            button!.setTitleColor(.white, for: .normal)
        }
    }
    
    private func processTranscriptToParagraphs() -> [Paragraph] {
        return transcriptTextView.text.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    @IBAction private func continueButtonTapped(_ sender: Any) {
        
        let transcriptParagraphs = processTranscriptToParagraphs()
        let metadata = LessonMetadata(title: lessonTitleField.text!, author: authorField.text!, transcript: transcriptParagraphs)
        
        guard metadata.isValid() else {
            let alertView = UIAlertController(title: "Incomplete Lesson Information",
                                              message: "Make sure you've filled out all the fields before continuing.",
                                              preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertView.addAction(okAction)
            present(alertView, animated: true)
            return
        }
        
        let recordingVC = storyboard?.instantiateViewController(withIdentifier: "AuthorRecordingViewController") as! AuthorRecordingViewController
        navigationController?.pushViewController(recordingVC, animated: true)
        recordingVC.metadata = metadata
    }
    
    @IBAction func SpeechBtnTapped(_ sender: Any) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            speechBtn.setTitle("Speech", for: .normal)
        } else {
            startRecording()
            preSpeechText = self.transcriptTextView.text
            speechBtn.setTitle("Stop", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
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
                self.transcriptTextView.text =  self.preSpeechText + (result?.bestTranscription.formattedString ?? "")
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.speechBtn.setTitle("Speech", for: .normal)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { (buffer, when) in
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

extension AuthoringMetadataViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == lessonTitleField {
            authorField.becomeFirstResponder()
        } else if textField == authorField {
            transcriptTextView.becomeFirstResponder()
        }
        return true
    }
}

extension AuthoringMetadataViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}
