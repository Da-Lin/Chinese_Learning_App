import UIKit
import FirebaseFirestore
import AVFoundation
import Speech
import Foundation

class StudentAudioFeedbackViewController: UIViewController,AVAudioPlayerDelegate {
    
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
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFeedBack()
        audioTimeSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        audioToText()
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: dataPath)
            audioPlayer.delegate = self
            audioTimeSlider.maximumValue = Float(audioPlayer.duration)
            _ = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
        }catch{
            print(error)
        }
        
        if !isTeacher{
            //feedbackButton.isHidden = true
        }
        
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
            default:
                break
            }
        }
    }
    
    func audioToText(){

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        let request = SFSpeechURLRecognitionRequest(url: dataPath)

        request.shouldReportPartialResults = true
        //print(dataPath.absoluteString + "asdasdasdasdadasdasasd")
        if (recognizer?.isAvailable)! {

            recognizer?.recognitionTask(with: request) { result, error in
                guard error == nil else { print("Error occured: \(error!)"); return }
                guard result != nil else { print("No result!"); return }
                
            }
        } else {
            print("Device doesn't support speech recognition")
        }
    }
    
    func getFeedBack(){
        let audioRef = db.collection("audios").document(studentId)
        audioRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                if let feedbackMapCloud = data["feedback"] as? [String: String]{
                    self.feedbackMap = feedbackMapCloud
                    if let feedback = feedbackMapCloud[self.lessonTitle] {
                        //self.feedbackLabel.text = feedback
                    }
                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
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
