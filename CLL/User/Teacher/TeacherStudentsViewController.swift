import UIKit
import FirebaseAuth
import FirebaseFirestore

class TeacherStudentsViewController: UIViewController {
    @IBOutlet weak var studentsTableView: UITableView!
    
    let uid = Auth.auth().currentUser!.uid
    let db = Firestore.firestore()
    var studentIds = [String]()
    var studentNames = [String]()
    var studentIdToNames = [String : String]()
    var studentIdToUpdated = [String : Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        studentIds = [String]()
        studentNames = [String]()
        studentIdToUpdated = [String : Bool]()
        getStudents()
    }
    
    func getStudentMadeUpdate(_ studentId: String){
        let usersRef = db.collection("audios").document(studentId)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let updated = data["updated"] as? Bool{
                    self.studentIdToUpdated[studentId] = updated
                    if updated{
                        self.studentsTableView.reloadData()
                    }
                }else{
                    self.studentIdToUpdated[studentId] = false
                }
            } else {
                print("Document does not exist")
            }
        }
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
        for studentId in studentIds{
            getStudentMadeUpdate(studentId)
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
                    let studentName = "\(firstName) \(lastName)"
                    self.studentIdToNames[studentId] = studentName
                    if self.studentIdToNames.count == size{
                        for studentId in self.studentIds{
                            self.studentNames.append(self.studentIdToNames[studentId] ?? "Student Not Found")
                        }
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
        if studentIdToUpdated[studentIds[indexPath.row]] ?? false{
            cell.backgroundColor = UIColor.red
        }else{
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentNames.count
    }
}
