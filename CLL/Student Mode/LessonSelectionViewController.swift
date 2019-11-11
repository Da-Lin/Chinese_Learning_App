import UIKit
import NVActivityIndicatorView
import FirebaseAuth

class LessonSelectionViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    private var lessons = [Lesson]()
    @IBOutlet weak var spinner: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select a Lesson"
        view.backgroundColor = .backgroundGrey
        
        spinner.type = .lineScaleParty
        spinner.color = .primaryRed
        spinner.startAnimating()
        
        LessonModel.sharedInstance.fetchAllLessons { [weak self] (lessons, error) in
            self?.lessons = lessons
            self?.spinner.stopAnimating()
            self?.tableView.reloadData()
        }
        
        //presentNewUserNamePrompt()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func presentNewUserNamePrompt() {
        
        if UserDefaults.standard.string(forKey: "STUDENT_NAME") != nil {
            return
        }
        if Auth.auth().currentUser != nil{
            return
        }
        
        let alertController = UIAlertController(title: "Who are you?", message: "We see you're new here. Please enter your name to get started!", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Jane Smith"
        }
        let confirmAction = UIAlertAction(title: "Let's go!", style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            UserDefaults.standard.set(textField.text ?? "", forKey: "STUDENT_NAME")
        }
        
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension LessonSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let studentVC = storyboard?.instantiateViewController(withIdentifier: "StudentModeViewController") as! StudentModeViewController
        studentVC.lesson = lessons[indexPath.row]
        navigationController?.pushViewController(studentVC, animated: true)
    }
}

extension LessonSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "\"\(lessons[indexPath.row].title)\" - \(lessons[indexPath.row].authorName)"
        return cell
    }
    
}
