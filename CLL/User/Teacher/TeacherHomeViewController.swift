import UIKit
import FirebaseAuth
import FlatUIKit

class TeacherHomeViewController: UIViewController {

    @IBOutlet weak var newLessonButton: FUIButton!
    @IBOutlet weak var viewStudentsButton: FUIButton!
    @IBOutlet weak var tutorialButton: FUIButton!
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
        [viewStudentsButton, newLessonButton, tutorialButton].forEach { button in
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
    
    @IBAction func newLessonButtonTapped(_ sender: Any) {
        let sentenceVC = storyboard?.instantiateViewController(withIdentifier: "AuthoringMetadataViewController") as! AuthoringMetadataViewController
        navigationController?.pushViewController(sentenceVC, animated: true)
    }
    
    @IBAction func tutorialButtonTapped(_ sender: Any) {
        let tutorialViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.tutorialViewController) as! TutorialViewController
        tutorialViewController.link = "https://www.youtube.com/embed/c-gD_2X5RTk?playsinline=1"
        navigationController?.pushViewController(tutorialViewController, animated: true)
    }
    
}
