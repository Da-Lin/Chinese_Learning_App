import UIKit
import FirebaseAuth
import FlatUIKit

class StudentHomeViewController: UIViewController {
    @IBOutlet weak var lessonsButton: FUIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSignOutButtonTapped))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    @IBAction func lessonButtonTapped(_ sender: Any) {
        let lessonSelectionVC = storyboard?.instantiateViewController(withIdentifier: "LessonSelectionViewController") as! LessonSelectionViewController
        navigationController?.pushViewController(lessonSelectionVC, animated: true)
    }
    
    private func setupButtons() {
        [lessonsButton].forEach { button in
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
