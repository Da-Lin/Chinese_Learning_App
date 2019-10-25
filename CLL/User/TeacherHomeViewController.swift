import UIKit
import FirebaseAuth

class TeacherHomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSignOutButtonTapped))
        self.navigationItem.leftBarButtonItem = newBackButton
        // Do any additional setup after loading the view.
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
