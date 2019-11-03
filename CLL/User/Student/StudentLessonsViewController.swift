import UIKit
import FirebaseFirestore
import FirebaseAuth

class StudentLessonsViewController: UIViewController {
    @IBOutlet weak var lessonTable: UITableView!
    
    var uid = Auth.auth().currentUser!.uid
    var lessons = [String]()
    var isTeacher = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLessons();
        // Do any additional setup after loading the view.
    }
    
    func getLessons(){
        let db = Firestore.firestore()
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if !self.isTeacher{
                    if let lessons = data["lessons"] as? [String]{
                        self.lessons = lessons
                        self.lessonTable.reloadData()
                    }
                }else{
                    if let lessons = data["submittedLessons"] as? [String]{
                        self.lessons = lessons
                        self.lessonTable.reloadData()
                    }
                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
}

extension StudentLessonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let studentAudioRecordsViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.studentAudioRecordsController) as! StudentAudioRecordsViewController
        studentAudioRecordsViewController.lessonTitle = lessons[indexPath.row]
        studentAudioRecordsViewController.isTeacher = isTeacher
        studentAudioRecordsViewController.uid = uid
        self.navigationController?.pushViewController(studentAudioRecordsViewController, animated: true)
    }
}

extension StudentLessonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = lessons[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
}
