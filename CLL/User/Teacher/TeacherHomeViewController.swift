import UIKit
import FirebaseAuth
import FlatUIKit

class TeacherHomeViewController: UIViewController {

    @IBOutlet weak var viewStudentsButton: FUIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        view.backgroundColor = .primaryRed

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSignOutButtonTapped))
        self.navigationItem.leftBarButtonItem = newBackButton
        // Do any additional setup after loading the view.
    }
    
    private func setupButtons() {
        [viewStudentsButton].forEach { button in
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

    @IBAction func viewStudentsButtonTapped(_ sender: Any) {
        let teacherStudentsVC = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.teacherStudentsViewController) as! TeacherStudentsViewController
        navigationController?.pushViewController(teacherStudentsVC, animated: true)
    }
}
