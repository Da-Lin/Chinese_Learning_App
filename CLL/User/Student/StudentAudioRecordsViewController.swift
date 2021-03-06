import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

class StudentAudioRecordsViewController: UIViewController {
    
    @IBOutlet weak var recordsTableView: UITableView!
    
    public var lessonTitle = ""
    var uid = Auth.auth().currentUser!.uid
    let db = Firestore.firestore()
    var isTeacher = false
    
    var submitted = false;
    
    public var audioURLs = [String]()
    public var timeStamps = [TimeInterval]()
    var updateds = [Bool]()
    var feedbackUpdateds = [Bool]()
    public var existsFlags = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if !isTeacher{
            initValue()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        audioURLs = [String]()
        timeStamps = [TimeInterval]()
        updateds = [Bool]()
        feedbackUpdateds = [Bool]()
        existsFlags = [Bool]()
        getAuidos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !feedbackUpdateds.contains(true){
            self.db.collection("audios").document(self.uid).collection(self.lessonTitle).document("feedbackUpdates").setData(["updated": false]) { (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
        }
    }
    
    func initValue(){
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let submittedLessons = data["submittedLessons"] as? [String]{
                    if submittedLessons.contains(self.lessonTitle){
                        self.submitted = true
                    }else{
                        self.submitted = false
                    }
                }
                self.setUpNavButtons()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    //    func setUpFeedbackButton(){
    //        let feedbackButton = UIBarButtonItem(title: "Provide Feedback", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleFeedbackButtonTapped))
    //        self.navigationItem.rightBarButtonItem = feedbackButton
    //    }
    
    func setUpNavButtons(){
        let submitButton = UIBarButtonItem(title: "Submit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleSubmitButtonTapped))
        if submitted{
            submitButton.title = "Cancel Submission"
        }
        //        let feedbackButton = UIBarButtonItem(title: "View Feedback", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleFeedbackButtonTapped))
        self.navigationItem.rightBarButtonItem = submitButton
    }
    
    //    @objc func handleFeedbackButtonTapped(){
    //        let studentLessonFeedbackViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.studentLessonFeedbackViewController) as! StudentAudioFeedbackViewController
    //        studentLessonFeedbackViewController.isTeacher = isTeacher
    //        studentLessonFeedbackViewController.studentId = uid
    //        studentLessonFeedbackViewController.lessonTitle = lessonTitle
    //        self.navigationController?.pushViewController(studentLessonFeedbackViewController, animated: true)
    //    }
    
    @objc func handleSubmitButtonTapped(){
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if var submittedLessons = data["submittedLessons"] as? [String]{
                    if !submittedLessons.contains(self.lessonTitle){
                        self.submitted = true
                        submittedLessons.append(self.lessonTitle)
                        self.setSubmittedLesson(submittedLessons)
                    }else{
                        self.submitted = false
                        submittedLessons.removeAll{$0 == self.lessonTitle}
                        self.setSubmittedLesson(submittedLessons)
                    }
                }else{
                    self.submitted = true
                    let submittedLessons = [self.lessonTitle]
                    self.setSubmittedLesson(submittedLessons)
                }
                self.setUpNavButtons()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func setSubmittedLesson(_ submittedLessons: [String]){
        let usersRef = self.db.collection("users").document(self.uid)
        usersRef.updateData(["submittedLessons": submittedLessons]) { (error) in
            if error != nil {
                // Show error message
                print("Error saving user data")
            }
        }
    }
    
    func getAuidos(){
        db.collection("audios").document(uid).collection(lessonTitle).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if TimeInterval(document.documentID) == nil{
                        continue
                    }
                    self.timeStamps.append(TimeInterval(document.documentID)!)
                    let data = document.data()
                    let urlStr = data["url"] as! String
                    self.audioURLs.append(urlStr)
                    if let updated = data["updated"] as? Bool{
                        self.updateds.append(updated)
                    }else{
                        self.updateds.append(false)
                    }
                    if let updated = data["feedbackUpdated"] as? Bool{
                        self.feedbackUpdateds.append(updated)
                    }else{
                        self.feedbackUpdateds.append(false)
                    }
                    //print("\(document.documentID) => \(document.data())")
                }
                self.cashAudioFiles()
                self.recordsTableView.reloadData()
            }
        }
    }
    
    func cashAudioFiles(){
        if timeStamps.count == 0 {
            return 
        }
        for i in 0...timeStamps.count - 1{
            let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[i]) + ".mp4")
            if FileManager.default.fileExists(atPath: dataPath.relativePath) {
                //existsFlags.append(true)
            }else{
                //existsFlags.append(false)
                let url = audioURLs[i]
                let storageRef = Storage.storage().reference()
                let userAudioRef = storageRef.child(url)
                let downloadTask = userAudioRef.write(toFile: dataPath) { url, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                        print(error)
                    } else {
                        // Local file URL for "images/island.jpg" is returned
                    }
                }
                
                downloadTask.observe(.progress) { snapshot in
                    // Download reported progress
                    //                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    //                        / Double(snapshot.progress!.totalUnitCount)
                    
                    //print(percentComplete)
                }
                
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}

extension StudentAudioRecordsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[indexPath.row]) + ".mp4")
        if FileManager.default.fileExists(atPath: dataPath.relativePath) {
            
            let studentAudioFeedbackViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.studentAudioFeedbackViewController) as! StudentAudioFeedbackViewController
            studentAudioFeedbackViewController.isTeacher = isTeacher
            studentAudioFeedbackViewController.studentId = uid
            studentAudioFeedbackViewController.lessonTitle = lessonTitle
            studentAudioFeedbackViewController.dataPath = dataPath
            studentAudioFeedbackViewController.audioTimeStamp = String(timeStamps[indexPath.row])
            if isTeacher && updateds[indexPath.row] {
                updateds[indexPath.row] = false
                recordsTableView.reloadData()
                db.collection("audios").document(uid).collection(lessonTitle).document(String(timeStamps[indexPath.row])).updateData(["updated": false]) { (error) in
                    if error != nil {
                        // Show error message
                        print("Error saving user data")
                    }
                }
                
                //if all records are reviewed
                if !updateds.contains(true){
                    
                    //mark lesson as unupdated
                    db.collection("audios").document(uid).collection(self.lessonTitle).document("updates").setData(["updated": false]) { (error) in
                        if error != nil {
                            // Show error message
                            print("Error saving user data")
                        }
                    }
                    
                    //remove this lesson from students updated lessons array. If no lessons left, mark student as unupdated
                    let usersRef = db.collection("users").document(uid)
                    usersRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let data = document.data()!
                            //student updated lessons
                            var updatedLessons:[String]
                            if data["updatedLessons"] != nil{
                                updatedLessons = data["updatedLessons"] as! [String]
                            }else{
                                updatedLessons = [String]()
                            }
                            if let index = updatedLessons.firstIndex(of: self.lessonTitle){
                                updatedLessons.remove(at: index)
                                usersRef.updateData(["updatedLessons": updatedLessons]) { (error) in
                                    if error != nil {
                                        // Show error message
                                        print("Error saving user data")
                                    }
                                }
                                
                                if updatedLessons.count == 0{
                                    self.db.collection("audios").document(self.uid).setData(["updated": false]) { (error) in
                                        if error != nil {
                                            // Show error message
                                            print("Error saving user data")
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                
                }
            }
            self.navigationController?.pushViewController(studentAudioFeedbackViewController, animated: true)
        }
        
    }
}

extension StudentAudioRecordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeStamps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let time = NSDate(timeIntervalSince1970: TimeInterval(timeStamps[indexPath.row]))
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date / server String
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: time as Date)
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = timeString
        if isTeacher {
            if updateds[indexPath.row]{
                cell.backgroundColor = UIColor.red
            }else{
                cell.backgroundColor = UIColor.white
            }
        }else{
            if feedbackUpdateds[indexPath.row]{
                cell.backgroundColor = UIColor.red
            }else{
                cell.backgroundColor = UIColor.white
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isTeacher
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if (editingStyle == .delete) {
            
            //remove local file
            let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[index]) + ".mp4")
            if FileManager.default.fileExists(atPath: dataPath.relativePath) {
                //existsFlags.append(true)
                do {
                    try FileManager.default.removeItem(at: dataPath)
                } catch{
                    print(error)
                }
            }
            
            //remove cloud file reference
            let url = audioURLs[index]
            let storageRef = Storage.storage().reference()
            let userAudioRef = storageRef.child(url)
            userAudioRef.delete { error in
                if let error = error {
                    print(error)
                } else {
                    // File deleted successfully
                }
            }
            
            //remove database reference
            db.collection("audios").document(uid).collection(lessonTitle).document(String(timeStamps[index])).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    //print("Document successfully removed!")
                }
            }
            
            audioURLs.remove(at: index)
            timeStamps.remove(at: index)
            updateds.remove(at: index)
            feedbackUpdateds.remove(at: index)
            
            //if deleted all audios
            if timeStamps.count == 0{
                let usersRef = db.collection("users").document(uid)
                usersRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()!
                        var lessons = data["lessons"] as! [String]
                        lessons.removeAll{$0 == self.lessonTitle}
                        usersRef.updateData(["lessons": lessons]) { (error) in
                            if error != nil {
                                // Show error message
                                print("Error saving user data")
                            }
                        }
                        
                    } else {
                        print("Document does not exist")
                    }
                }
                navigationController?.popViewController(animated: true)
            }
            
            recordsTableView.reloadData()
        }
    }
}
