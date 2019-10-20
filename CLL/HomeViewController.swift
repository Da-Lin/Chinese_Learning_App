import UIKit
import FlatUIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var lessonsButton: FUIButton!
    @IBOutlet weak var authoringButton: FUIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.black,
             NSAttributedString.Key.font: UIFont.regularFont(ofSize: 22)]
        
        title = "Bubble Chinese"
        view.backgroundColor = .primaryRed
        customizeBackButton()
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func customizeBackButton() {
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        navigationController?.navigationBar.tintColor = .black
    }
    
    private func setupButtons() {
        [lessonsButton, authoringButton].forEach { button in
            guard let button = button else { return }
            button.buttonColor = .white
            button.shadowColor = .darkGray
            button.shadowHeight = 3.0
            button.cornerRadius = 6.0
            button.titleLabel?.font = .regularFont(ofSize: 22)
            button.setTitleColor(.black, for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func lessonsButtonTapped(_ sender: Any) {
        let lessonSelectionVC = storyboard?.instantiateViewController(withIdentifier: "LessonSelectionViewController") as! LessonSelectionViewController
        navigationController?.pushViewController(lessonSelectionVC, animated: true)
    }

    @IBAction private func authorButtonTapped(_ sender: Any) {
        promptForAuthoringToolPassword()
    }
    
    private func promptForAuthoringToolPassword() {
        
        guard !UserDefaults.standard.bool(forKey: "AUTHOR_HAS_AUTHENTICATED") else {
            navigateToAuthoringTool()
            return
        }
        
        let alertController = UIAlertController(title: "Are you a content author?", message: "If so, please enter your password to use the Authoring Tool.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "password"
            textField.isSecureTextEntry = true
        }
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            if textField.text == "CLL2018" {
                UserDefaults.standard.set(true, forKey: "AUTHOR_HAS_AUTHENTICATED")
                self?.navigateToAuthoringTool()
            }
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func navigateToAuthoringTool() {
        let sentenceVC = storyboard?.instantiateViewController(withIdentifier: "AuthoringMetadataViewController") as! AuthoringMetadataViewController
        navigationController?.pushViewController(sentenceVC, animated: true)
    }
    
}

