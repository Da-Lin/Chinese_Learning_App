import UIKit
import IoniconsKit

enum ToneType: Int {
    case first = 1  // high and level
    case second     // rising
    case third      // falling, rising
    case fourth     // falling
    case fifth      // neutral
    
    func color() -> UIColor {
        switch self {
        case .first:
            return .yellow
        case .second:
            return .red
        case .third:
            return .green
        case .fourth:
            return .cyan
        case .fifth:
            return .white
        }
    }
    
    func markerSymbol() -> String {
        switch self {
        case .first:
            return "—"
        case .second:
            return "/"
        case .third:
            return "⋁"
        case .fourth:
            return "\\"
        case .fifth:
            return ""
        }
    }
}

final class ToneBubbleView: UIView {
    
    let label = UILabel()
    let stressBackgroundLabel = UILabel()
    let stressOutlineLabel = UILabel()
    
    private var tone: ToneType?
    private var isStressed = false
    
    func setTone(tone: ToneType?, _ isStressed: Bool) {
        self.tone = tone
        self.isStressed = isStressed
        updateTone()
    }
    
    private func updateTone() {
        addSubview(stressBackgroundLabel)
        stressBackgroundLabel.textAlignment = .center
        
        stressBackgroundLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stressBackgroundLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stressBackgroundLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        addSubview(stressOutlineLabel)
        stressOutlineLabel.textAlignment = .center
        stressOutlineLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stressOutlineLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stressOutlineLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        addSubview(label)
        label.textAlignment = .center
        label.text = tone?.markerSymbol()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        stressBackgroundLabel.isHidden = !isStressed
        stressOutlineLabel.isHidden = !isStressed
        
        clipsToBounds = false
        
        if isStressed {
            stressBackgroundLabel.font = .ionicon(of: 40)
            stressBackgroundLabel.textColor = tone?.color()
            stressBackgroundLabel.text = .ionicon(with: .iosStar)
            
            stressOutlineLabel.font = .ionicon(of: 44)
            stressOutlineLabel.textColor = .black
            stressOutlineLabel.text = .ionicon(with: .iosStarOutline)
            
            label.font = UIFont.systemFont(ofSize: 17)
            
            backgroundColor = .clear
            layer.cornerRadius = 0
            layer.borderWidth = 0
        } else {
            backgroundColor = tone?.color()
            layer.masksToBounds = true
            layer.cornerRadius = 17.0
            layer.borderWidth = 2.0
            layer.borderColor = UIColor.darkGray.cgColor
        }

    }
}

struct IndividualCharacterViewMetadata {
    let isStressed: Bool
    let isLong: Bool
    let toneNumber: Int
    let character: String
}

final class CharacterView: UICollectionViewCell {

    private let toneBubble = ToneBubbleView()
    private let characterLabel = UILabel()
    private var toneBubbleWidthConstraint: NSLayoutConstraint!
    private let pinyin = UILabel()
    
    var metadata: IndividualCharacterViewMetadata? {
        didSet {
            refreshLabels()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = .salmon
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = .salmon
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // Tone bubble Layout
        toneBubbleWidthConstraint = toneBubble.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.45)
        contentView.addSubview(toneBubble)
        toneBubble.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toneBubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            toneBubble.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            toneBubble.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.35),
            toneBubbleWidthConstraint
            ])
        
        // Pinyin layout
        contentView.addSubview(pinyin)
        pinyin.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
           pinyin.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
           pinyin.widthAnchor.constraint(equalTo: contentView.widthAnchor),
           pinyin.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
           pinyin.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
           ])
               
        pinyin.text = "中".transformToPinYin()
        pinyin.font = .regularFont(ofSize: 20)

        pinyin.textAlignment = .center
    
        // Character label layout
        contentView.addSubview(characterLabel)
        characterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            characterLabel.topAnchor.constraint(equalTo: pinyin.bottomAnchor, constant: 1),
            characterLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            characterLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            characterLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            characterLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            ])
        
        characterLabel.text = "--"
        characterLabel.font = .regularFont(ofSize: 20)

        characterLabel.textAlignment = .center
    }
    
    private func refreshLabels() {
        characterLabel.text = metadata?.character
        pinyin.text = metadata?.character.transformToPinYin()
        toneBubble.setTone(tone: ToneType(rawValue: metadata!.toneNumber), metadata!.isStressed)

        if metadata!.toneNumber == 0 {
            toneBubble.isHidden = true
        } else {
            toneBubble.isHidden = false
        }
        
        NSLayoutConstraint.deactivate([toneBubbleWidthConstraint])
        if metadata!.isLong {
            toneBubbleWidthConstraint = toneBubble.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0)
        } else {
            toneBubbleWidthConstraint = toneBubble.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.45)
        }
        NSLayoutConstraint.activate([toneBubbleWidthConstraint])
    }
    
}
