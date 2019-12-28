import UIKit
import FirebaseFirestore
import AVFoundation
import Speech
import Foundation
import FirebaseStorage
import FirebaseAuth

class StudentAudioFeedbackViewController: UIViewController,AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var audioTimeSlider: UISlider!
    @IBOutlet weak var audioTime: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var feedbackTableView: UITableView!
    
    var isTeacher = false
    var studentId = ""
    var feedbackMap = [String: String]()
    var lessonTitle = ""
    var dataPath: URL!
    var audioPlayer: AVAudioPlayer!
    var feedbackAudioPlayer: AVAudioPlayer!
    var feedbackButton: UIBarButtonItem!
    var feedbackTime = ""
    var audioTimeStamp = ""
    var feedbackFileName: String!
    var feedbackFileNameURL: URL!
    var uid = Auth.auth().currentUser!.uid
    var feedbackTimes = [String]()
    var feedbackURLs = [String]()
    var feedbackFileNames = [String]()
    var feedbackUpdateds = [Bool]()
    private var timer = Timer()
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioPlayer()
        getFeedbackAudio()
        if isTeacher{
            setUpFeedbackButton()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
        feedbackAudioPlayer = nil
        audioPlayer = nil
        
        if !isTeacher { db.collection("audios").document(self.studentId).collection(self.lessonTitle).document(self.audioTimeStamp).updateData(["feedbackUpdateds": self.feedbackUpdateds]) { (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
            
            if !feedbackUpdateds.contains(true){
                db.collection("audios").document(self.studentId).collection(self.lessonTitle).document(self.audioTimeStamp).updateData(["feedbackUpdated": false]) { (error) in
                    if error != nil {
                        // Show error message
                        print("Error saving user data")
                    }
                }
                
                //lessons that have updated feedback
                let db = Firestore.firestore()
                let usersRef = db.collection("users").document(self.studentId)
                usersRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()!
                        var updatedFeedbackLessons:[String]
                        if data["updatedFeedbackLessons"] != nil{
                            updatedFeedbackLessons = data["updatedFeedbackLessons"] as! [String]
                        }else{
                            updatedFeedbackLessons = [String]()
                        }
                        if let index = updatedFeedbackLessons.firstIndex(of: self.lessonTitle){
                            updatedFeedbackLessons.remove(at: index)
                            usersRef.updateData(["updatedFeedbackLessons": updatedFeedbackLessons]) { (error) in
                                if error != nil {
                                    // Show error message
                                    print("Error saving user data")
                                }
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            }
        }
    }
    
    func getFeedbackAudio(){
        let db = Firestore.firestore()
        
        let audioRef = db.collection("audios").document(self.studentId).collection(self.lessonTitle).document(self.audioTimeStamp)
        audioRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let feedbackURLsCloud = data["feedbackURLs"] as? [String]{
                    self.feedbackURLs = feedbackURLsCloud
                }
                if let feedbackTimesCloud = data["feedbackTimes"] as? [String]{
                    self.feedbackTimes = feedbackTimesCloud
                }
                if let feedbackFileNamesCloud = data["feedbackFileNames"] as? [String]{
                    self.feedbackFileNames = feedbackFileNamesCloud
                }
                if let feedbackupdatedsCloud = data["feedbackUpdateds"] as? [Bool]{
                    self.feedbackUpdateds = feedbackupdatedsCloud
                }
                self.cashAudioFiles()
                self.feedbackTableView.reloadData()
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func cashAudioFiles(){
        if feedbackTimes.count == 0 {
            return
        }
        for i in 0...feedbackTimes.count - 1{
            let dataPath = getDocumentsDirectory().appendingPathComponent(feedbackFileNames[i])
            if FileManager.default.fileExists(atPath: dataPath.relativePath) {
                //existsFlags.append(true)
            }else{
                //existsFlags.append(false)
                let url = feedbackURLs[i]
                let storageRef = Storage.storage().reference()
                let userAudioRef = storageRef.child(url)
                _ = userAudioRef.write(toFile: dataPath) { url, error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                        print(error)
                    } else {
                        // Local file URL for "images/island.jpg" is returned
                    }
                }
            }
        }
    }
    
    func setupAudioRecorder(){
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try recordingSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Failed to grant microphone recording permission!")
                    }
                }
            }
        } catch {
            print(error)
            print("Failed to configure audio recording session!")
        }
    }
    
    func setupAudioPlayer(){
        audioTimeSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: dataPath)
            audioPlayer.delegate = self
            audioTimeSlider.maximumValue = Float(audioPlayer.duration)
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
        }catch{
            print(error)
        }
    }
    
    func setUpFeedbackButton(){
        feedbackButton = UIBarButtonItem(title: "Record Feedback", style: UIBarButtonItem.Style.plain, target: self, action: #selector(handleFeedbackButtonTapped))
        self.navigationItem.rightBarButtonItem = feedbackButton
    }
    
    @objc func handleFeedbackButtonTapped(){
        if self.audioRecorder == nil{
            let alertController = UIAlertController(title: "Enter Time", message: "", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "00.00"
            }
            let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak alertController] _ in
                guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
                self!.feedbackTime = textField.text!
                self!.startRecording()
            }
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }else{
            audioRecorder.stop()
            audioRecorder = nil
            feedbackButton.title = "Record Feedback"
            uploadAudio()
        }
        
    }
    
    private func uploadAudio(){
        let timestamp = NSDate().timeIntervalSince1970
        let storageRef = Storage.storage().reference()
        let url = "audios/feedback/" + uid + "/" + lessonTitle + "/" + String(timestamp) + ".mp4"
        let userAudioRef = storageRef.child(url)
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"
        
        let uploadTask = userAudioRef.putFile(from: feedbackFileNameURL, metadata: metadata)
        
        uploadTask.observe(.success) { snapshot in
            
            self.feedbackURLs.append(url)
            self.feedbackTimes.append(self.feedbackTime)
            self.feedbackFileNames.append(self.feedbackFileName)
            self.feedbackUpdateds.append(true)
            self.feedbackTableView.reloadData()
            
            //lessons that have updated feedback
            let db = Firestore.firestore()
            let usersRef = db.collection("users").document(self.studentId)
            usersRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()!
                    var updatedFeedbackLessons:[String]
                    if data["updatedFeedbackLessons"] != nil{
                        updatedFeedbackLessons = data["updatedFeedbackLessons"] as! [String]
                    }else{
                        updatedFeedbackLessons = [String]()
                    }
                    if !updatedFeedbackLessons.contains(self.lessonTitle){
                        updatedFeedbackLessons.append(self.lessonTitle)
                        usersRef.updateData(["updatedFeedbackLessons": updatedFeedbackLessons]) { (error) in
                            if error != nil {
                                // Show error message
                                print("Error saving user data")
                            }
                        }
                    }
                } else {
                    print("Document does not exist")
                }
            }
            
            self.db.collection("audios").document(self.studentId).collection(self.lessonTitle).document("feedbackUpdates").setData(["updated": true]) { (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
            self.db.collection("audios").document(self.studentId).collection(self.lessonTitle).document(self.audioTimeStamp).updateData(["feedbackURLs":self.feedbackURLs,"feedbackTimes":self.feedbackTimes, "feedbackFileNames": self.feedbackFileNames, "feedbackUpdateds": self.feedbackUpdateds, "feedbackUpdated": true]) { (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
            
        }
        
        uploadTask.observe(.failure) { snapshot in
            self.dismiss(animated: false, completion: nil)
            if let error = snapshot.error as NSError? {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    print("File doesn't exist")
                    break
                case .unauthorized:
                    print("User doesn't have permission to access file")
                    break
                case .cancelled:
                    print("User canceled the upload")
                    break
                    
                    /* ... */
                    
                case .unknown:
                    print("Unknown error occurred, inspect the server response")
                    break
                default:
                    print("A separate error occurred. This is a good place to retry the upload.")
                    break
                }
            }
            
        }
        
    }
    
    func startRecording(){
        if self.audioRecorder == nil{
            let timestamp = NSDate().timeIntervalSince1970
            feedbackFileName = "\(timestamp).m4a"
            feedbackFileNameURL = self.getDocumentsDirectory().appendingPathComponent(feedbackFileName)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            do {
                self.audioRecorder = try AVAudioRecorder(url: feedbackFileNameURL, settings: settings)
                self.audioRecorder.delegate = self
                self.audioRecorder.record()
                feedbackButton.title = "Stop"
            } catch {
                print("Error starting recording session")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.setTitle("Play", for: UIControl.State.normal)
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                audioPlayer.stop()
            case .moved:
                audioPlayer.currentTime = TimeInterval(audioTimeSlider.value)
            case .ended:
                audioPlayer.currentTime = TimeInterval(audioTimeSlider.value)
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                playButton.setTitle("Pause", for: UIControl.State.normal)
            default:
                break
            }
        }
    }
    
    //    func audioToText(){
    //
    //        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    //        let request = SFSpeechURLRecognitionRequest(url: dataPath)
    //
    //        request.shouldReportPartialResults = true
    //        //print(dataPath.absoluteString + "asdasdasdasdadasdasasd")
    //        if (recognizer?.isAvailable)! {
    //
    //            recognizer?.recognitionTask(with: request) { result, error in
    //                guard error == nil else { print("Error occured: \(error!)"); return }
    //                guard result != nil else { print("No result!"); return }
    //
    //            }
    //        } else {
    //            print("Device doesn't support speech recognition")
    //        }
    //    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if audioPlayer.isPlaying{
            audioPlayer.stop()
            playButton.setTitle("Play", for: UIControl.State.normal)
        }else{
            audioPlayer.play()
            playButton.setTitle("Pause", for: UIControl.State.normal)
        }
        
    }
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        playButton.setTitle("Play", for: UIControl.State.normal)
    }
    
    @objc func updateSlider(){
        audioTimeSlider.value = Float(audioPlayer.currentTime)
        audioTime.text = String(format: "%.2f", Float(audioPlayer.currentTime))
    }
    
    
    @IBAction func feedbackButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter your feedback:", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Feedback"
        }
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            //self!.feedbackLabel.text = textField.text
            self!.feedbackMap[self!.lessonTitle] = textField.text
            self!.db.collection("audios").document(self!.studentId).setData(["feedback": self!.feedbackMap]){ (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

extension StudentAudioFeedbackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do{
            let path = getDocumentsDirectory().appendingPathComponent(feedbackFileNames[indexPath.row])
            feedbackAudioPlayer = try AVAudioPlayer(contentsOf: path)
            feedbackAudioPlayer.delegate = self
            feedbackAudioPlayer.prepareToPlay()
            feedbackAudioPlayer.play()
            if !isTeacher && feedbackUpdateds[indexPath.row]{
                feedbackUpdateds[indexPath.row] = false
                feedbackTableView.reloadData()
            }
        }catch{
            print(error)
        }
    }
}

extension StudentAudioFeedbackViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackAudioCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = feedbackTimes[indexPath.row]
        if !isTeacher && feedbackUpdateds[indexPath.row]{
            cell.backgroundColor = UIColor.red
        } else{
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedbackTimes.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isTeacher
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let index = indexPath.row
        if (editingStyle == .delete) {
            
            //remove local file
            let dataPath = URL(string: feedbackFileNames[index])!
            if FileManager.default.fileExists(atPath: dataPath.relativePath) {
                //existsFlags.append(true)
                do {
                    try FileManager.default.removeItem(at: dataPath)
                } catch{
                    print(error)
                }
            }
            
            //remove cloud file reference
            let url = feedbackURLs[index]
            let storageRef = Storage.storage().reference()
            let userAudioRef = storageRef.child(url)
            userAudioRef.delete { error in
                if let error = error {
                    print(error)
                } else {
                    // File deleted successfully
                }
            }
            
            //update database reference
            feedbackFileNames.remove(at: index)
            feedbackTimes.remove(at: index)
            feedbackURLs.remove(at: index)
            feedbackUpdateds.remove(at: index)
            db.collection("audios").document(self.studentId).collection(self.lessonTitle).document(self.audioTimeStamp).updateData(["feedbackURLs":self.feedbackURLs,"feedbackTimes":self.feedbackTimes, "feedbackFileNames": self.feedbackFileNames, "feedbackUpdateds": self.feedbackUpdateds]) { (error) in
                if error != nil {
                    // Show error message
                    print("Error saving user data")
                }
            }
            
            feedbackTableView.reloadData()
        }
    }
}
