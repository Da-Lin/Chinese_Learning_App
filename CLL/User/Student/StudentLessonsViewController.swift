import UIKit
import FirebaseFirestore
import FirebaseAuth

class StudentLessonsViewController: UIViewController {
    @IBOutlet weak var lessonTable: UITableView!
    
    var uid = Auth.auth().currentUser!.uid
    var lessons = [String]()
    var updatedLessons = [String]()
    var updatedFeedbackLessons = [String]()
    var isTeacher = false
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getLessons();
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
                    if let updatedFeedbackLessons = data["updatedFeedbackLessons"] as? [String]{
                        self.updatedFeedbackLessons = updatedFeedbackLessons
                        self.lessonTable.reloadData()
                    }
                }else{
                    if let lessons = data["submittedLessons"] as? [String]{
                        self.lessons = lessons
                        self.lessonTable.reloadData()
                    }
                    if let updatedLessons = data["updatedLessons"] as? [String]{
                        self.updatedLessons = updatedLessons
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
        if isTeacher{
            if updatedLessons.contains(lessons[indexPath.row]){
                cell.backgroundColor = UIColor.red
            }else{
                cell.backgroundColor = UIColor.white
            }
        }else{
            if updatedFeedbackLessons.contains(lessons[indexPath.row]){
                cell.backgroundColor = UIColor.red
            }else{
                cell.backgroundColor = UIColor.white
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
}
