import UIKit

protocol CharacterPopoverViewControllerObserver: class {
    func characterMetadataToneEdited(forIndexPath indexPath: IndexPath, toTone tone: Int)
    func characterMetadataStressEdited(forIndexPath indexPath: IndexPath, _ isStressed: Bool)
    func characterMetadataIsLongEdited(forIndexPath indexPath: IndexPath, _ isLong: Bool)
    func characterMetadataPinyinEdited(forIndexPath indexPath: IndexPath, _ toPinyin: String)
}

class CharacterPopoverViewController: UIViewController {

    var indexPath: IndexPath?
    weak var observer: CharacterPopoverViewControllerObserver?
    
    var metadata: IndividualCharacterViewMetadata? {
        didSet {
            refreshContent()
        }
    }
    
    @IBOutlet private weak var isLongSwitch: UISwitch!
    @IBOutlet private weak var isStressedSwitch: UISwitch!
    @IBOutlet private weak var toneSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var characterLabel: UILabel!
    @IBOutlet weak var pinyinText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isStressedSwitch.addTarget(self, action: #selector(stressedSwitchChanged(mySwitch:)), for: .valueChanged)
        isLongSwitch.addTarget(self, action: #selector(isLongSwitchChanged(mySwitch:)), for: .valueChanged)
        toneSegmentedControl.addTarget(self, action: #selector(toneNumberChanged(segmentedControl:)), for: .valueChanged)
    }
    
    @objc private func stressedSwitchChanged(mySwitch: UISwitch) {
        guard let indexPath = indexPath else { return }
        observer?.characterMetadataStressEdited(forIndexPath: indexPath, mySwitch.isOn)
    }
    
    @objc private func isLongSwitchChanged(mySwitch: UISwitch) {
        guard let indexPath = indexPath else { return }
        observer?.characterMetadataIsLongEdited(forIndexPath: indexPath, mySwitch.isOn)
    }
    
    @objc private func toneNumberChanged(segmentedControl: UISegmentedControl) {
        guard let indexPath = indexPath else { return }
        observer?.characterMetadataToneEdited(forIndexPath: indexPath, toTone: segmentedControl.selectedSegmentIndex + 1)
    }
    
    private func refreshContent() {
        loadViewIfNeeded()
        
        isLongSwitch.isOn = metadata!.isLong
        isStressedSwitch.isOn = metadata!.isStressed
        characterLabel.text = metadata!.character
        pinyinText.text = metadata!.pinyin
        toneSegmentedControl.selectedSegmentIndex = metadata!.toneNumber - 1
    }
    @IBAction func pinyinTextChanged(_ sender: Any) {
        guard let indexPath = indexPath else { return }
        //print(pinyinText.text!)
        observer?.characterMetadataPinyinEdited(forIndexPath: indexPath, pinyinText.text!)
    }
    
}
