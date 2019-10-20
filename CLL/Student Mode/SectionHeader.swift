import UIKit

final class SectionHeader: UICollectionReusableView {
    @IBOutlet weak var playButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        customizeButton()
    }
    
    private func customizeButton() {
        playButton.titleLabel?.font = .ionicon(of: 50)
        playButton.setTitleColor(.red, for: .normal)
        playButton.setTitle(.ionicon(with: .iosPlayOutline), for: .normal)
    }
}

