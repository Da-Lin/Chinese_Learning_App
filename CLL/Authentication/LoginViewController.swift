import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpElement()
        // Do any additional setup after loading the view.
    }
    
    func setUpElement(){
        errorLabel.alpha = 0
        
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(loginButton)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func loginButtonTapped(_ sender: Any) {
        // TODO: Validate Text Fields
        
        // Create cleaned versions of the text field
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        // Signing in the user
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if error != nil {
                // Couldn't sign in
                self.errorLabel.text = error!.localizedDescription
                self.errorLabel.alpha = 1
            }
            else {
                self.displaySpinner()
                let db = Firestore.firestore()
                let uid = result!.user.uid
                db.collection("users").document(uid).getDocument { (document, err) in
                    self.dismiss(animated: false, completion: nil)
                    if let document = document, document.exists {
                        let data = document.data()!
                        let role = data["role"] as! Int
                        if role == Constants.UserRole.teacher {
                            let teacherHomeViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.teacherHomeViewController) as! TeacherHomeViewController
                            self.navigationController?.pushViewController(teacherHomeViewController, animated: true)
                        }else{
                            let studentHomeViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.studentHomeViewController) as! StudentHomeViewController
                            self.navigationController?.pushViewController(studentHomeViewController, animated: true)
                        }
                        
                    } else {
                        print("Document does not exist")
                    }
                }
            }
        }
    }
    
    func displaySpinner(){
        let alert = UIAlertController(title: nil, message: "Logging in...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: false, completion: nil)
    }
    
}
