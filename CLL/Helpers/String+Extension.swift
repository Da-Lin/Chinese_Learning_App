import UIKit
import HanziPinyin

extension String {
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }
    
    subscript (r: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start...end])
    }
    
    func removeWhitespace() -> String {
        return replacingOccurrences(of: " ", with: "")
    }
}

extension String {
    func stripNonNumericsFromString() -> Int {
        let stringArray = self.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for item in stringArray {
            if let number = Int(item) {
                return number
            }
        }
        return 0
    }
}

extension String {
    func toneNumber() -> Int {
        guard self.hasChineseCharacter else { return 0 }
        let outputFormat = PinyinOutputFormat(toneType: .toneNumber, vCharType: .vCharacter, caseType: .lowercased)
        let toneNumber = self.toPinyin(withFormat: outputFormat, separator: " ").stripNonNumericsFromString()
        return toneNumber
    }
}
