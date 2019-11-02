import UIKit
import FirebaseAuth
import Firebase

class SignUpViewController: UIViewController {
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleSeg: UISegmentedControl!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var teacherEmailTextField: UITextField!
    
    var role = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElement()
        // Do any additional setup after loading the view.
    }
    
    func setUpElement(){
        errorLabel.alpha = 0
        
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(lastNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
        Utilities.styleTextField(teacherEmailTextField)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func validateFields() -> String? {
        
        // Check that all fields are filled in
        if firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "Please fill in all fields."
        }
        
        // Check if the password is secure
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedPassword.count < 6{
            return "Please make sure your password is at least 6 characters."
        }
        
//        if Utilities.isPasswordValid(cleanedPassword) == false {
//            // Password isn't secure enough
//            return "Please make sure your password is at least 8 characters, contains a special character and a number."
//        }
        
        return nil
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // There's something wrong with the fields, show error message
            showError(error!)
        }
        else {
            
            // Create cleaned versions of the data
            let firstName = firstNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let teacherEmail = teacherEmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create the user
            Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
                
                // Check for errors
                if err != nil {
                    // There was an error creating the user
                    self.showError(err!.localizedDescription)
                }
                else {
                    // User was created successfully, now store the first name and last name
                    let db = Firestore.firestore()
                    
                    db.collection("users").document(result!.user.uid).setData(["firstname":firstName, "lastname":lastName, "email": email, "uid": result!.user.uid, "role": self.role, "teacherEmail": teacherEmail ]) { (error) in
                         
                        if error != nil {
                            // Show error message
                            self.showError("Error saving user data")
                        }
                    }
                    
                    // Transition to the home screen
                    self.transitionToHome()
                }
                
            }
            
            
            
        }
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    
    func transitionToHome() {

        if role == Constants.UserRole.student{
            let studentHomeViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.studentHomeViewController) as! StudentHomeViewController
            navigationController!.pushViewController(studentHomeViewController, animated: false)
        }else{
            let teacherHomeViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.teacherHomeViewController) as! TeacherHomeViewController
            navigationController!.pushViewController(teacherHomeViewController, animated: false)
        }
    }
    
    @IBAction func roleSegChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            role = Constants.UserRole.student
        case 1:
            promptForAuthoringToolPassword()
        default:
            break
        }
    }
    
    private func promptForAuthoringToolPassword() {
        
//        guard !UserDefaults.standard.bool(forKey: "AUTHOR_HAS_AUTHENTICATED") else {
//            teacherAuth = true
//            return
//        }
        
        let alertController = UIAlertController(title: "Are you a content author?", message: "If so, please enter your password to use the Authoring Tool.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "password"
            textField.isSecureTextEntry = true
        }
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            if textField.text == "CLL2018" {
                UserDefaults.standard.set(true, forKey: "AUTHOR_HAS_AUTHENTICATED")
                self!.role = Constants.UserRole.teacher
                self!.roleSeg.selectedSegmentIndex = 1
            }else{
                self!.role = Constants.UserRole.student
                self!.roleSeg.selectedSegmentIndex = 0
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            self.role = Constants.UserRole.student
            self.roleSeg.selectedSegmentIndex = 0
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
}
