import UIKit
import FlatUIKit
import AVKit
import NVActivityIndicatorView

class AuthorAnnotationViewController: UIViewController {
    
    var metadata: LessonMetadata?
    var audioFileUrl: URL?
    
    @IBOutlet private weak var collectionView: UICollectionView!
    private var selectedIndexTimestamps = [IndexPath: Double]()

    @IBOutlet weak var annotateButton: FUIButton!
    @IBOutlet weak var publishButton: FUIButton!
    @IBOutlet weak var slowSpeedSwitch: UISwitch!
    private var popoverVC: CharacterPopoverViewController!
    private var panRecognizer: UIPanGestureRecognizer!
    private var spinner: NVActivityIndicatorView?
    
    private var audioPlayer: AVAudioPlayer!
    private var isPlaying = false
    private var audioStartTime: Double = 0.0
    
    typealias ParagraphMetadata = [IndividualCharacterViewMetadata]
    
    private var characterMetadata = [ParagraphMetadata]()
    
    private var currentPlaybackRate: Float {
        return slowSpeedSwitch.isOn ? 0.5 : 1.0
    }
    
    private func hasValidAnnotation() -> Bool {
        let characterCount = metadata!.transcript.flatMap{$0}.count
        let selectedCount = selectedIndexTimestamps.values.count
        return selectedCount == characterCount
    }
    
    private func resetTheWorld() {
        if !selectedIndexTimestamps.isEmpty {
            collectionView.reloadData()
        }
        
        if panRecognizer.view == nil {
            collectionView.addGestureRecognizer(panRecognizer)
        }
        
        collectionView.contentOffset = .zero
        audioStartTime = 0.0
        slowSpeedSwitch.isUserInteractionEnabled = false
        publishButton.isEnabled = false
        selectedIndexTimestamps = [:]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGrey
        title = "Annotate Lesson"
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    
        popoverVC = (storyboard?.instantiateViewController(withIdentifier: "CharacterPopoverViewController") as! CharacterPopoverViewController)
        popoverVC.observer = self
        
        setupButtons()
    
        for paragraph in metadata!.transcript {
            let paragraphMetadata: ParagraphMetadata = paragraph.map { String($0) }.map { character in
                return IndividualCharacterViewMetadata(isStressed: false, isLong: false, toneNumber: character.toneNumber(), character: character)
            }
            characterMetadata.append(paragraphMetadata)
        }
        
        collectionView!.register(CharacterView.self, forCellWithReuseIdentifier: "Cell")
        collectionView.delegate = self
        collectionView.dataSource = self

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanToSelectCells(panGesture:)))
        panRecognizer.cancelsTouchesInView = false
        
        slowSpeedSwitch.layer.cornerRadius = 16
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        popoverVC.dismiss(animated: true, completion: nil)
    }

    
    // MARK: - IBActions
    
    private func convertIndividualMetadataToTranscriptMetadata() -> [LessonParagraphMetadata] {
        
        var transcriptMetadata = [LessonParagraphMetadata]()
        for (sectionIdx, paragraphMetadata) in characterMetadata.enumerated() {
            
            var newParagraphMetadata = LessonParagraphMetadata()
            for (rowIdx, character) in paragraphMetadata.enumerated() {
                let charMetadata = CharacterMetadata(character: character.character, startTime: selectedIndexTimestamps[IndexPath(row: rowIdx, section: sectionIdx)] ?? 0, isStressed: character.isStressed, isLong: character.isLong, toneNumber: character.toneNumber)
                newParagraphMetadata.append(charMetadata)
            }
            transcriptMetadata.append(newParagraphMetadata)
        }

        return transcriptMetadata
    }
    
    @IBAction private func publishTapped(_ sender: Any) {
        debugPrint(selectedIndexTimestamps)
        
        guard let audioUrl = audioFileUrl else { return }
        
        let transcriptMetadata = convertIndividualMetadataToTranscriptMetadata()
        let lesson = Lesson(title: metadata!.title, authorName: metadata!.author, audioFile: audioUrl, transcriptMetadata: transcriptMetadata)
        
        publishButton.setTitleColor(.clear, for: .disabled)
        publishButton.isEnabled = false
        spinner?.startAnimating()
        
        LessonModel.sharedInstance.saveLesson(lesson) { [weak self] error in
            if error != nil {
                let alertView = UIAlertController(title: "Unable to Publish Lesson",
                                                  message: "Your lesson could not be saved at this time. Please try again.",
                                                  preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                alertView.addAction(okAction)
                self?.present(alertView, animated: true)
            } else {
                let alertView = UIAlertController(title: "Lesson Published!",
                                                  message: "Your lesson was successfully published. Tap to return to the home screen.",
                                                  preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] alert in
                    let vc =  self?.navigationController?.viewControllers.filter({$0 is TeacherHomeViewController}).first
                    self?.navigationController?.popToViewController(vc!, animated: true)
                }
                alertView.addAction(okAction)
                self?.present(alertView, animated: true)
            }
            
            
            self?.spinner?.stopAnimating()
            self?.publishButton.setTitleColor(.white, for: .disabled)
            self?.publishButton.isEnabled = true
        }
    }
    
    @IBAction private func annotateButtonTapped(_ sender: Any) {
        if isPlaying {
            // Stop button tapped
            audioPlayer.stop()
            finishAnnotation()
            
        } else {
            // Annotate button tapped
            guard FileManager.default.fileExists(atPath: audioFileUrl!.path) else {
                print("Audio file is missing!")
                return
            }
            
            annotateButton.setTitle("Stop", for: .normal)
            resetTheWorld()
            prepareForAudioPlayback()
            audioPlayer.enableRate = true
            audioPlayer.rate = currentPlaybackRate
            audioPlayer.play()
            audioStartTime = Date.timeIntervalSinceReferenceDate
            isPlaying = true
        }
    }
    
    private func prepareForAudioPlayback() {
        
        guard FileManager.default.fileExists(atPath: audioFileUrl!.path) else {
            print("This file should exist!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl!)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch {
            print("Unable to initialize AVAudioPlayer with contents of \(String(describing: audioFileUrl!))")
        }
    }
    
    @objc private func didPanToSelectCells(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            
        } else if panGesture.state == .changed {
            let location = panGesture.location(in: collectionView)
            guard let indexPath = collectionView.indexPathForItem(at: location) else { return }

            let cellIsNew = !selectedIndexTimestamps.keys.contains(indexPath)

            if cellIsNew && cellIsNextCellSinceLastSelected(indexPath) && isPlaying {

                selectedIndexTimestamps[indexPath] = Double(currentPlaybackRate) * (Date.timeIntervalSinceReferenceDate - audioStartTime)
                handleLastCharacterBeingHighlightedIfNeeded()
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredVertically)
                moveToNextCellIfNeeded(forIndexPath: indexPath)
            }
            
        } else if panGesture.state == .ended {
            
        }
    }
    
    private func handleLastCharacterBeingHighlightedIfNeeded() {
        if hasValidAnnotation() {
            if self.isPlaying {
                self.audioPlayer.stop()
                self.finishAnnotation()
            }
        }
    }
    
    private func setupButtons() {
        for button in [annotateButton, publishButton] {
            button!.buttonColor = .primaryRed
            button!.shadowColor = .black
            button!.shadowHeight = 3.0
            button!.cornerRadius = 6.0
            button!.titleLabel?.font = .regularFont(ofSize: 20)
            button!.setTitleColor(.white, for: .normal)
        }
        
        publishButton.isEnabled = false
        setupSubmittingLoadingSpinner()
    }
    
    private func setupSubmittingLoadingSpinner() {
        spinner = NVActivityIndicatorView(frame: .zero, type: .lineScale, color: .white, padding: nil)
        publishButton.addSubview(spinner!)
        
        spinner!.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner!.heightAnchor.constraint(equalTo: publishButton.heightAnchor, multiplier: 0.5),
            spinner!.widthAnchor.constraint(equalToConstant: 40),
            spinner!.centerXAnchor.constraint(equalTo: publishButton.centerXAnchor),
            spinner!.centerYAnchor.constraint(equalTo: publishButton.centerYAnchor)
            ])
    }
    
    private func finishAnnotation() {
        isPlaying = false
        slowSpeedSwitch.isUserInteractionEnabled = true
        annotateButton.setTitle("Annotate", for: .normal)
        collectionView.removeGestureRecognizer(panRecognizer)
        if hasValidAnnotation() {
            publishButton.isEnabled = true
        }
    }
    
    private func cellIsNextCellSinceLastSelected(_ indexPath: IndexPath) -> Bool {
        let indexPathIsZero = indexPath.row == 0 && indexPath.section == 0
        
        var previousIndexPath: IndexPath
        if indexPath.section > 0 && indexPath.row == 0 {
            let newRow = characterMetadata[indexPath.section - 1].count - 1
            previousIndexPath = IndexPath(row: newRow, section: indexPath.section - 1)
        } else {
            previousIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
        }
        
        return (selectedIndexTimestamps.isEmpty && indexPathIsZero) ||
            selectedIndexTimestamps.keys.contains(previousIndexPath)
    }
    
}

extension AuthorAnnotationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 20, height: 20) // currently not doing anything
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard hasValidAnnotation() && !isPlaying else { return false }
        let metadata = characterMetadata[indexPath.section][indexPath.row]
        let toneBubbleIsHidden = metadata.toneNumber == 0
        return !toneBubbleIsHidden
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        popoverVC.indexPath = indexPath
        popoverVC.metadata = characterMetadata[indexPath.section][indexPath.row]
        
        let cell = collectionView.cellForItem(at: indexPath)!
        popoverVC.modalPresentationStyle = .popover
        popoverVC.popoverPresentationController?.sourceView = collectionView
        popoverVC.popoverPresentationController?.sourceRect = cell.frame
        popoverVC.popoverPresentationController?.delegate = self
        
        present(popoverVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let cellIsNew = !selectedIndexTimestamps.keys.contains(indexPath)

        if !isPlaying && hasValidAnnotation() {
            return true
        } else if cellIsNew && cellIsNextCellSinceLastSelected(indexPath) && isPlaying {
            return true
        } else {
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if isPlaying {
            selectedIndexTimestamps[indexPath] = Double(currentPlaybackRate) * (Date.timeIntervalSinceReferenceDate - audioStartTime)
            handleLastCharacterBeingHighlightedIfNeeded()
            moveToNextCellIfNeeded(forIndexPath: indexPath)
        }
    }
    
    private func moveToNextCellIfNeeded(forIndexPath indexPath: IndexPath) {
        let numSections = characterMetadata.count
        let isLastSection = (indexPath.section - 1 == numSections)
        let numRowsInSection = characterMetadata[indexPath.section].count
        let isLastRowInSection = (indexPath.row == numRowsInSection - 1)
        
        guard !(isLastSection && isLastRowInSection) else { return }
        var nextItem: IndexPath
        if isLastRowInSection {
            nextItem = IndexPath(row: 0, section: indexPath.section + 1)
        } else {
            nextItem = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        }
        
        if collectionView.cellForItem(at: nextItem) != nil {
            collectionView.scrollToItem(at: nextItem, at: .centeredVertically, animated: false)
        }
    }
}

extension AuthorAnnotationViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return metadata?.transcript[section].count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // 1 section per "paragraph"
        return metadata?.transcript.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CharacterView
        cell.metadata = characterMetadata[indexPath.section][indexPath.row]
        
        if selectedIndexTimestamps.keys.contains(indexPath) {
            cell.backgroundColor = .salmon
        } else {
            cell.backgroundColor = .clear
        }
        return cell
    }
}

extension AuthorAnnotationViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            guard let this = self else { return }
            if this.isPlaying {
                this.finishAnnotation()
            }
        }
    }
}

extension AuthorAnnotationViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        // This is valuable if we want to handle rotation. Right now, we just dismiss.
        /*
        guard let currentlySelectedItem = collectionView.indexPathsForSelectedItems?.first else { return }
        if let cell = collectionView.cellForItem(at: currentlySelectedItem) {
            view.pointee = collectionView
            rect.initialize(to: cell.frame)
        }
        */
    }
}

extension AuthorAnnotationViewController: CharacterPopoverViewControllerObserver {
    func characterMetadataToneEdited(forIndexPath indexPath: IndexPath, toTone tone: Int) {
        let previousMetadata = characterMetadata[indexPath.section][indexPath.row]
        characterMetadata[indexPath.section][indexPath.row] = IndividualCharacterViewMetadata(isStressed: previousMetadata.isStressed, isLong: previousMetadata.isLong, toneNumber: tone, character: previousMetadata.character)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func characterMetadataStressEdited(forIndexPath indexPath: IndexPath, _ isStressed: Bool) {
        let previousMetadata = characterMetadata[indexPath.section][indexPath.row]
        characterMetadata[indexPath.section][indexPath.row] = IndividualCharacterViewMetadata(isStressed: isStressed, isLong: previousMetadata.isLong, toneNumber: previousMetadata.toneNumber, character: previousMetadata.character)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func characterMetadataIsLongEdited(forIndexPath indexPath: IndexPath, _ isLong: Bool) {
        let previousMetadata = characterMetadata[indexPath.section][indexPath.row]
        characterMetadata[indexPath.section][indexPath.row] = IndividualCharacterViewMetadata(isStressed: previousMetadata.isStressed, isLong: isLong, toneNumber: previousMetadata.toneNumber, character: previousMetadata.character)
        collectionView.reloadItems(at: [indexPath])
    }
}

