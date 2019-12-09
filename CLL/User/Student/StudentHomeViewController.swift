import UIKit
import FirebaseAuth
import FlatUIKit
import FirebaseFirestore

class StudentHomeViewController: UIViewController {
    
    @IBOutlet weak var lessonsButton: FUIButton!
    @IBOutlet weak var checkSavedLessonsButton: FUIButton!
    @IBOutlet weak var changeTeacherButton: FUIButton!
    @IBOutlet weak var tutorialButton: FUIButton!
    
    let uid = Auth.auth().currentUser!.uid
    let db = Firestore.firestore()
    
    var teacherEmail = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSignOutButtonTapped))
        self.navigationItem.leftBarButtonItem = newBackButton
        view.backgroundColor = .primaryRed
        setupButtons()
        initValue()
    }
    
    private func initValue(){
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let teacherEmail = data["teacherEmail"] {
                    self.teacherEmail = teacherEmail as! String
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let value =  UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    @IBAction func lessonButtonTapped(_ sender: Any) {
        let lessonSelectionVC = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.lessonSelectionViewController) as! LessonSelectionViewController
        navigationController?.pushViewController(lessonSelectionVC, animated: true)
    }
    @IBAction func checkSavedLessonsButtonTapped(_ sender: Any) {
        let studentLessonsController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.studentLessonsController) as! StudentLessonsViewController
        navigationController?.pushViewController(studentLessonsController, animated: true)
    }
    
    @IBAction func changeTeacherButtonTapped(_ sender: Any) {
        promptForEnteringEmail()
    }
    
    private func setupButtons() {
        [lessonsButton, checkSavedLessonsButton, changeTeacherButton, tutorialButton].forEach { button in
            guard let button = button else { return }
            button.buttonColor = .white
            button.shadowColor = .darkGray
            button.shadowHeight = 3.0
            button.cornerRadius = 6.0
            button.titleLabel?.font = .regularFont(ofSize: 22)
            button.setTitleColor(.black, for: .normal)
        }
    }
    
    @objc func handleSignOutButtonTapped(){
        do{
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let err {
            print(err)
        }
    }
    
    private func promptForEnteringEmail() {
        let alertController = UIAlertController(title: "Enter your teacher's email:", message: "Your current teacher email address is \(teacherEmail)", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Teacher Email Address"
        }
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            self!.checkAndUpdateTeacherEmail(textField.text!)
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func checkAndUpdateTeacherEmail(_ teacherEmailEntered: String){
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        if teacherEmailEntered == teacherEmail{
            alertController.title = "This email is already your teacher email"
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        db.collection("users").whereField("role", isEqualTo: 1).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var found = false
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let teacherEmailCloud = data["email"] as? String {
                        if teacherEmailCloud == teacherEmailEntered{
                            
                            //new teacher add student
                            self.db.collection("users").whereField("email", isEqualTo: teacherEmailEntered).getDocuments() { (querySnapshot, err) in
                                if let err = err {
                                    print("Error getting documents: \(err)")
                                } else {
                                    for document in querySnapshot!.documents {
                                        let data = document.data()
                                        var students = [String]()
                                        if let studentsCloud = data["students"]{
                                            students = studentsCloud as! [String]
                                        }
                                        if !students.contains(self.uid){
                                            students.append(self.uid)
                                            self.db.collection("users").document(data["uid"] as! String).updateData(["students": students]){ (error) in
                                                if error != nil {
                                                    // Show error message
                                                    print("Error saving user data")
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                            }
                            
                            //old teacher removed student
                            self.db.collection("users").whereField("email", isEqualTo: self.teacherEmail).getDocuments() { (querySnapshot, err) in
                                if let err = err {
                                    print("Error getting documents: \(err)")
                                } else {
                                    for document in querySnapshot!.documents {
                                        let data = document.data()
                                        var students = [String]()
                                        if let studentsCloud = data["students"]{
                                            students = studentsCloud as! [String]
                                        }
                                        students.removeAll{$0 == self.uid}
                                        self.db.collection("users").document(data["uid"] as! String).updateData(["students": students]){ (error) in
                                            if error != nil {
                                                // Show error message
                                                print("Error saving user data")
                                            }
                                        }
                                    }
                                }
                            }
                            self.teacherEmail = teacherEmailEntered
                            found = true
                            alertController.title = "Teacher email successfully updated."
                            let usersRef = self.db.collection("users").document(self.uid)
                            usersRef.updateData(["teacherEmail": teacherEmailEntered]) { (error) in
                                if error != nil {
                                    // Show error message
                                    print("Error saving user data")
                                }
                            }
                        }
                    }
                }
                if !found{
                    alertController.message = "Teacher email entered is not found."
                }
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func tutorialButtonTapped(_ sender: Any) {
        let tutorialViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.tutorialViewController) as! TutorialViewController
        tutorialViewController.link = "https://www.youtube.com/embed/-fWx_w-csy4?playsinline=1"
        navigationController?.pushViewController(tutorialViewController, animated: true)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}
