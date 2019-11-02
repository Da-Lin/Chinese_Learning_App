import UIKit
import FirebaseAuth
import FlatUIKit

class StudentHomeViewController: UIViewController {
    
    @IBOutlet weak var lessonsButton: FUIButton!
    @IBOutlet weak var checkSavedLessonsButton: FUIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSignOutButtonTapped))
        self.navigationItem.leftBarButtonItem = newBackButton
        view.backgroundColor = .primaryRed
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    @IBAction func lessonButtonTapped(_ sender: Any) {
        let lessonSelectionVC = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.lessonSelectionViewController) as! LessonSelectionViewController
        navigationController?.pushViewController(lessonSelectionVC, animated: true)
    }
    @IBAction func checkSavedLessonsButtonTapped(_ sender: Any) {
        let studentLessonsController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.studentLessonsController) as! StudentLessonsViewController
        navigationController?.pushViewController(studentLessonsController, animated: true)
    }
    
    private func setupButtons() {
        [lessonsButton, checkSavedLessonsButton].forEach { button in
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
    
}
