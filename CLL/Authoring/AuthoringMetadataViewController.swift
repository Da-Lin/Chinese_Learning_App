import UIKit
import JVFloatLabeledTextField
import FlatUIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create New Lesson"
        view.backgroundColor = .backgroundGrey
        continueButton.layer.shadowColor = UIColor.darkGray.cgColor
        setupButtons()
    }

    private func setupButtons() {
        for button in [continueButton] {
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
