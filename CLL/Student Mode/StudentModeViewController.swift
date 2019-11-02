import UIKit
import FlatUIKit
import AVKit
import IoniconsKit
import MessageUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

private enum IndividualParagraphPlaybackStatus {
    case inactive
    case paragraph(Int)
}

final class StudentModeViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    // Instructor's audio playback
    private var audioPlayer: AVAudioPlayer!
    @IBOutlet weak var instructorPlayStopButton: FUIButton!
    @IBOutlet weak var pauseResumeButton: FUIButton!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedStepper: UIStepper!
    
    private var speakingSpeed: Float = 1.0
    
    private var timeElapsedIntoPlayback: Double = 0.0
    private var indexOfCurrentSpokenCharacter: IndexPath?
    private var characterStartTimes = [Double]()
    
    // Student's voice recording and audio playback:
    @IBOutlet private weak var recordButton: FUIButton!
    @IBOutlet private weak var showRecordButton: FUIButton!
    @IBOutlet private weak var studentAudioPlaybackButton: FUIButton!
    
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var studentRecordingFileName: URL!
    
    private var timer = Timer()
    private var isPlaying = false
    private var isRecording = false
    private var isStudentRecordingPlaying = false
    private var paragraphPlaybackStatus = IndividualParagraphPlaybackStatus.inactive
    
    let numOfAudios = 0
    
    var lesson: Lesson? {
        didSet {
            refreshContent()
        }
    }
    
    private func refreshContent() {
        loadViewIfNeeded()
        characterStartTimes = lesson!.transcriptMetadata.joined().map { $0.startTime }
        debugPrint(characterStartTimes)
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = lesson?.title
        view.backgroundColor = .backgroundGrey
        
        setupButtons()
        collectionView!.register(CharacterView.self, forCellWithReuseIdentifier: "Cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        requestRecordingAccess()
        
        speedStepper.minimumValue = 0.5
        speedStepper.maximumValue = 2.0
        speedStepper.stepValue = 0.1
        speedLabel.text = String(format: "Speed: %.2f", speakingSpeed)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        audioPlayerStopped()
    }
    
    // MARK: - Initial Setup
    
    private func requestRecordingAccess() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [weak self] allowed in
                guard let this = self else { return }
                DispatchQueue.main.async {
                    if !allowed {
                        this.recordButton.isEnabled = false
                        print("Failed to grant microphone recording permission!")
                    }
                }
            }
        } catch {
            print("Failed to configure audio recording session!")
        }
    }
    
    private func setupButtons() {
        for button in [recordButton, pauseResumeButton, studentAudioPlaybackButton, showRecordButton, instructorPlayStopButton] {
            button!.buttonColor = .primaryRed
            button!.shadowColor = .black
            button!.shadowHeight = 3.0
            button!.cornerRadius = 6.0
            button!.titleLabel?.font = .regularFont(ofSize: 20)
            button!.setTitleColor(.white, for: .normal)
        }
        
        pauseResumeButton.titleLabel?.font = .ionicon(of: 20)
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
        
        recordButton.isEnabled = true
        instructorPlayStopButton.isEnabled = true
        
        pauseResumeButton.isHidden = true
        showRecordButton.isHidden = false
        studentAudioPlaybackButton.isHidden = true
    }
    
    private func audioPlayerStopped() {
        instructorPlayStopButton.setTitle("Play", for: .normal)
        instructorPlayStopButton.isEnabled = true
        pauseResumeButton.isHidden = true
        isPlaying = false
        isStudentRecordingPlaying = false
        studentAudioPlaybackButton.setTitle("Listen", for: .normal)
        speedStepper.isEnabled = true
        recordButton.isEnabled = true
        showRecordButton.isEnabled = true
        studentAudioPlaybackButton.isEnabled = true
        invalidateTimer()
        indexOfCurrentSpokenCharacter = nil
        timeElapsedIntoPlayback = 0.0
        paragraphPlaybackStatus = .inactive
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction private func startStopInstructorPlaybackButtonTapped(_ sender: Any) {
        
        guard FileManager.default.fileExists(atPath: lesson!.audioFile.path) else {
            print("Audio file is missing!")
            return
        }
        
        guard !isPlaying else {
            audioPlayer.stop()
            audioPlayerStopped()
            return
        }
        
        prepareForAudioPlayback()
        audioPlayer.enableRate = true
        audioPlayer.rate = speakingSpeed
        audioPlayer.play()
        startTimer()
        isPlaying = true
        speedStepper.isEnabled = false
        instructorPlayStopButton.setTitle("Stop", for: .normal)
        recordButton.isEnabled = false
        showRecordButton.isEnabled = false
        studentAudioPlaybackButton.isEnabled = false
        
        pauseResumeButton.isHidden = false
        pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
    }
    
    @IBAction private func pauseResumeButtonTapped(_ sender: Any) {
        if audioRecorder != nil{
            if audioRecorder.isRecording{
                audioRecorder.pause()
                invalidateTimer()
                pauseResumeButton.setTitle(.ionicon(with: .iosPlay), for: .normal)
            }else{
                audioRecorder.record()
                startTimer()
                pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
            }
        }else{
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                invalidateTimer()
                pauseResumeButton.setTitle(.ionicon(with: .iosPlay), for: .normal)
            } else {
                audioPlayer.play()
                startTimer()
                pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
            }
        }
        
    }
    
    private func startTimer() {
        collectionView.isScrollEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    }
    
    private func invalidateTimer() {
        collectionView.isScrollEnabled = true
        timer.invalidate()
    }
    
    @objc private func timerLoop() {
        
        timeElapsedIntoPlayback += Double(0.05 * speakingSpeed)
        let lastIndex = indexOfCurrentSpokenCharacter
        
        let flattenedIndex = characterStartTimes.lastIndex { (startTime) -> Bool in
            return timeElapsedIntoPlayback >= startTime
            } ?? 0
        
        // print("FLATTENED INDEX: updates to \(flattenedIndex)")
        
        var counter = 0
        searchForCurrentCharacter: for sectionIndex in 0 ..< lesson!.transcriptMetadata.count {
            let section = lesson!.transcriptMetadata[sectionIndex]
            for rowIndex in 0 ..< section.count {
                if counter == flattenedIndex {
                    indexOfCurrentSpokenCharacter = IndexPath(row: rowIndex, section: sectionIndex)
                    break searchForCurrentCharacter
                }
                counter += 1
            }
        }
        
        // If playing individual paragraphs, make sure to stop before the subsequent paragraph starts playing.
        if case .paragraph(let paragraphNumber) = paragraphPlaybackStatus {
            if paragraphNumber + 1 < lesson!.transcriptMetadata.count {
                if indexOfCurrentSpokenCharacter == IndexPath(row: 0, section: paragraphNumber + 1) {
                    audioPlayer.stop()
                    audioPlayerStopped()
                    return
                }
            }
        }
        
        if indexOfCurrentSpokenCharacter! != lastIndex {
            collectionView.scrollToItem(at: indexOfCurrentSpokenCharacter!, at: [.centeredVertically], animated: false)
            
            UIView.performWithoutAnimation {
                let paths = [lastIndex, indexOfCurrentSpokenCharacter].compactMap { $0 }
                self.collectionView.reloadItems(at: paths)
            }
        }
    }
    
    @IBAction private func stepperSpeedChanged(_ sender: UIStepper) {
        speakingSpeed = Float(sender.value)
        speedLabel.text = String(format: "Speed: %.2f", speakingSpeed)
    }
    
    
    // MARK: - Speech Recording -------
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
        
        // STOP button tapped:
        guard audioRecorder == nil else {
            finishRecording(success: true)
            updateButtons(forState: .notRecording)
            return
        }
        
        // Record button tapped:
        updateButtons(forState: .recording)
        startRecording()
        isRecording = true
    }
    
    private func startRecording() {
        let studentName = UserDefaults.standard.string(forKey: "STUDENT_NAME") ?? ""
        let filename = studentName + "_" + lesson!.title + "_" + String(Int.random(in: 0 ..< 10000))
        
        studentRecordingFileName = getDocumentsDirectory().appendingPathComponent("\(filename).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: studentRecordingFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setTitle("Stop", for: .normal)
            
            // Start animation
            startTimer()
        } catch {
            print("Error starting recording session")
        }
    }
    
    let alert = UIAlertController(title: nil, message: "Uploading file: 0%", preferredStyle: .alert)
    func displaySpinner(percentComplete: Int){
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: false, completion: nil)
    }
    
    private func uploadAudio(){
        if let uid = Auth.auth().currentUser?.uid{
            let timestamp = NSDate().timeIntervalSince1970
            let storageRef = Storage.storage().reference()
            let url = "audios/" + uid + "/" + lesson!.title + "/" + String(timestamp) + ".mp4"
            let userAudioRef = storageRef.child(url)
            let metadata = StorageMetadata()
            metadata.contentType = "audio/mp4"
            
            let uploadTask = userAudioRef.putFile(from: studentRecordingFileName, metadata: metadata)
            self.displaySpinner(percentComplete: 0)
            uploadTask.observe(.progress) { snapshot in
                // Upload reported progress
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                let percentage = String(format: "%.0f", percentComplete)
                self.alert.message = "Uploading file: \(percentage)%"
                print(percentComplete)
            }
            
            uploadTask.observe(.success) { snapshot in
                print("successful")
                do{
                    
                    let docURL = self.getDocumentsDirectory()
                    let dataPath = docURL.appendingPathComponent(self.lesson!.title)
                    if !FileManager.default.fileExists(atPath: dataPath.relativePath) {
                        do {
                            try FileManager.default.createDirectory(atPath: dataPath.relativePath, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print(error.localizedDescription);
                        }
                    }
                    let destinationPath = self.getDocumentsDirectory().appendingPathComponent(self.lesson!.title).appendingPathComponent("\(String(timestamp)).m4a")
                    try FileManager.default.moveItem(at: self.studentRecordingFileName, to: destinationPath)
                    if FileManager.default.fileExists(atPath: self.studentRecordingFileName!.path) {
                        print("exists original")
                    }else{
                        print("not exists original")
                    }
                    self.studentRecordingFileName = destinationPath
                    if FileManager.default.fileExists(atPath: destinationPath.path) {
                        print("exists new")
                    }else{
                        print("not exists new")
                    }
                } catch{
                    print("ERROR - \(error)")
                }
                
                self.dismiss(animated: false, completion: nil)
                
                //upload lessons data to firestore
                let newLesson = self.lesson!.title + " - " + self.lesson!.authorName
                let db = Firestore.firestore()
                let usersRef = db.collection("users").document(uid)
                usersRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()!
                        var lessons:[String]
                        if data["Lessons"] != nil{
                            lessons = data["Lessons"] as! [String]
                        }else{
                            lessons = [String]()
                        }
                        if !lessons.contains(newLesson){
                            lessons.append(newLesson)
                            usersRef.updateData(["Lessons": lessons]) { (error) in
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
                db.collection("audios").document(uid).collection(newLesson).document(String(timestamp)).setData(["title":newLesson, "url": url]) { (error) in
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
    }
    
    private func finishRecording(success: Bool) {
        print("Recording finished with success: \(success)")
        audioRecorder.stop()
        audioRecorder = nil
        isRecording = false
        uploadAudio()
        
        invalidateTimer()
        indexOfCurrentSpokenCharacter = nil
        timeElapsedIntoPlayback = 0.0
        collectionView.reloadData()
    }
    
    enum StudentState {
        case recording
        case notRecording
    }
    
    private func updateButtons(forState state: StudentState) {
        switch state {
        case .recording:
            pauseResumeButton.isHidden = false
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
            showRecordButton.isHidden = true
            instructorPlayStopButton.isEnabled = false
            studentAudioPlaybackButton.isHidden = true
            studentAudioPlaybackButton.isEnabled = true
            
        case .notRecording: // more precisely, "DONE recording":
            pauseResumeButton.isHidden = true
            pauseResumeButton.setTitle(.ionicon(with: .iosPause), for: .normal)
            showRecordButton.isHidden = false
            instructorPlayStopButton.isEnabled = true
            studentAudioPlaybackButton.isHidden = false
            recordButton.setTitle("Re-Record", for: .normal)
        }
    }
    
    // MARK: - Playing back recorded audio
    
    private func prepareForAudioPlayback(isStudentRecording: Bool = false) {
        
        let audioFile = isStudentRecording ? studentRecordingFileName : lesson!.audioFile
        
        guard FileManager.default.fileExists(atPath: audioFile!.path) else {
            print("This file should exist!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile!)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch {
            print("Unable to initialize AVAudioPlayer with contents of \(String(describing: studentRecordingFileName))")
        }
    }
    
    @IBAction private func studentRecordingPlayButtonTapped(_ sender: Any) {
        
        if isStudentRecordingPlaying {
            // Stop playback
            audioPlayer.stop()
            audioPlayerStopped()
        } else {
            // Start playback
            guard FileManager.default.fileExists(atPath: studentRecordingFileName.path) else {
                print("Audio file is missing!")
                return
            }
            studentAudioPlaybackButton.setTitle("Stop", for: .normal)
            recordButton.isEnabled = false
            showRecordButton.isEnabled = false
            instructorPlayStopButton.isEnabled = false
            
            prepareForAudioPlayback(isStudentRecording: true)
            audioPlayer.play()
            isStudentRecordingPlaying = true
        }
    }
    
    @IBAction private func viewRecordButtonTapped(_ sender: Any) {
        if Auth.auth().currentUser?.uid != nil{
            let studentAudioRecordsViewController = self.storyboard!.instantiateViewController(identifier: Constants.Storyboard.studentAudioRecordsController) as! StudentAudioRecordsViewController
            studentAudioRecordsViewController.lessonTitle = lesson!.title
            self.navigationController?.pushViewController(studentAudioRecordsViewController, animated: true)
        }
        
        
        
        //        guard MFMailComposeViewController.canSendMail() else {
        //            let alertView = UIAlertController(title: "Email Account Not Configured",
        //                                              message: "To share this lesson via email, you must first have a Mail account created on this device.",
        //                                              preferredStyle: .alert)
        //            let okAction = UIAlertAction(title: "OK", style: .default)
        //            alertView.addAction(okAction)
        //            present(alertView, animated: true)
        //            return
        //        }
        //
        //        let mailComposer = MFMailComposeViewController()
        //        mailComposer.mailComposeDelegate = self
        //
        //        let studentName = UserDefaults.standard.string(forKey: "STUDENT_NAME") ?? ""
        //        mailComposer.setSubject("Bubble Chinese - \(lesson!.title)")
        //        mailComposer.setMessageBody("Student name: \(studentName)\n\nLessonName: \(lesson!.title)\n\nAudio submission attached.", isHTML: false)
        //
        //        if let fileData = NSData(contentsOfFile: studentRecordingFileName.path) {
        //            mailComposer.addAttachmentData(fileData as Data, mimeType: "audio/mp4", fileName: studentRecordingFileName.lastPathComponent)
        //        }
        //        present(mailComposer, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc private func playIndividualParagraph(sender: UIButton) {
        
        // Don't allow paragraph playback while a recording is in progress.
        guard !isRecording else { return }
        
        let paragraphToPlay = sender.tag
        
        if isPlaying {
            audioPlayer.stop()
            audioPlayerStopped()
        }
        
        let startTime = lesson!.transcriptMetadata[paragraphToPlay].first?.startTime
        paragraphPlaybackStatus = .paragraph(paragraphToPlay)
        timeElapsedIntoPlayback = startTime ?? 0
        startStopInstructorPlaybackButtonTapped(sender)
        audioPlayer.currentTime = startTime ?? 0
        print("Playing paragraph \(sender.tag)")
    }
}

extension Array {
    subscript (safe index: UInt) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}

extension StudentModeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as? SectionHeader {
            sectionHeader.playButton.tag = indexPath.section
            sectionHeader.playButton.addTarget(self, action: #selector(playIndividualParagraph(sender:)), for: .touchUpInside)
            return sectionHeader
        }
        return UICollectionReusableView()
    }
}

extension StudentModeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lesson?.transcriptMetadata[section].count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return lesson?.transcriptMetadata.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CharacterView
        let metadata = lesson!.transcriptMetadata[indexPath.section][indexPath.row]
        let individualMetadata = IndividualCharacterViewMetadata(isStressed: metadata.isStressed, isLong: metadata.isLong, toneNumber: metadata.toneNumber, character: metadata.character)
        cell.metadata = individualMetadata
        
        if indexOfCurrentSpokenCharacter == nil {
            cell.backgroundColor = .clear
        } else if indexPath == indexOfCurrentSpokenCharacter {
            cell.backgroundColor = .salmon
        } else {
            cell.backgroundColor = .clear
        }
        
        return cell
    }
}

extension StudentModeViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension StudentModeViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayerStopped()
    }
}

extension StudentModeViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
