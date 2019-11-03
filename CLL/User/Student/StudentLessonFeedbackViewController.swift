import UIKit
import FirebaseFirestore

class StudentLessonFeedbackViewController: UIViewController {
    
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var feedbackButton: UIButton!
    
    var isTeacher = false
    var studentId = ""
    var feedbackMap = [String: String]()
    var lessonTitle = ""
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFeedBack()
        
        if !isTeacher{
            feedbackButton.isHidden = true
        }
        
    }
    
    func getFeedBack(){
        let audioRef = db.collection("audios").document(studentId)
        audioRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let feedbackMapCloud = data["feedback"] as? [String: String]{
                    self.feedbackMap = feedbackMapCloud
                    if let feedback = feedbackMapCloud[self.lessonTitle] {
                        self.feedbackLabel.text = feedback
                    }
                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    @IBAction func feedbackButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter your feedback:", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Feedback"
        }
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            self!.feedbackLabel.text = textField.text
            self!.feedbackMap[self!.lessonTitle] = textField.text
            self!.db.collection("audios").document(self!.studentId).setData(["feedback": self!.feedbackMap]){ (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
