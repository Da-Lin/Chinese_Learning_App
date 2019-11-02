import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

class StudentAudioRecordsViewController: UIViewController {
    
    @IBOutlet weak var recordsTableView: UITableView!
    
    public var lessonTitle = ""
    let uid = Auth.auth().currentUser!.uid
    let db = Firestore.firestore()
    
    var audioPlayer: AVAudioPlayer!
    
    public var audioURLs = [String]()
    public var timeStamps = [TimeInterval]()
    public var existsFlags = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getAuidos()
    }
    
    func getAuidos(){
        db.collection("audios").document(uid).collection(lessonTitle).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    self.timeStamps.append(TimeInterval(document.documentID)!)
                    let data = document.data()
                    let urlStr = data["url"] as! String
                    self.audioURLs.append(urlStr)
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
            let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[i]))
            if FileManager.default.fileExists(atPath: dataPath.relativePath) {
                //existsFlags.append(true)
            }else{
                //existsFlags.append(false)
                let url = audioURLs[i]
                let storageRef = Storage.storage().reference()
                let userAudioRef = storageRef.child(url)
                let localURL = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[i]))
                let downloadTask = userAudioRef.write(toFile: localURL) { url, error in
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
        let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[indexPath.row]))
        if FileManager.default.fileExists(atPath: dataPath.relativePath) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: dataPath)
                audioPlayer?.play()
            } catch {
                // couldn't load file :(
            }
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if (editingStyle == .delete) {
            
            //remove local file
            let dataPath = self.getDocumentsDirectory().appendingPathComponent(lessonTitle).appendingPathComponent(String(timeStamps[index]))
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
            
            //if deleted all audios
            if timeStamps.count == 0{
                let usersRef = db.collection("users").document(uid)
                usersRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()!
                        var lessons = data["Lessons"] as! [String]
                        lessons.removeAll{$0 == self.lessonTitle}
                        usersRef.updateData(["Lessons": lessons]) { (error) in
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
