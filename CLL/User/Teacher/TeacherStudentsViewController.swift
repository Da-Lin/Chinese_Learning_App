import UIKit
import FirebaseAuth
import FirebaseFirestore

class TeacherStudentsViewController: UIViewController {
    @IBOutlet weak var studentsTableView: UITableView!
    
    let uid = Auth.auth().currentUser!.uid
    let db = Firestore.firestore()
    var studentIds = [String]()
    var studentNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        getStudents()
        // Do any additional setup after loading the view.
    }
    
    func getStudents(){
        let db = Firestore.firestore()
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let students = data["students"] as? [String]{
                    self.studentIds = students
                    self.setStudentNames()
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func setStudentNames(){
        let size = studentIds.count
        var i = 0
        for studentId in studentIds{
            i += 1
            let usersRef = db.collection("users").document(studentId)
            usersRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()!
                    var firstName = "", lastName = ""
                    if let firstNameCloud = data["firstname"] as? String{
                        firstName = firstNameCloud
                    }
                    if let lastNameCloud = data["lastname"] as? String{
                        lastName = lastNameCloud
                    }
                    self.studentNames.append("\(firstName) \(lastName)")
                    if i == size{
                        self.studentsTableView.reloadData()
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
    }

}

extension TeacherStudentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let studentLessonsController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.studentLessonsController) as! StudentLessonsViewController
        studentLessonsController.uid = studentIds[indexPath.row]
        studentLessonsController.isTeacher = true
        navigationController?.pushViewController(studentLessonsController, animated: true)
    }
}

extension TeacherStudentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = studentNames[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentNames.count
    }
}
