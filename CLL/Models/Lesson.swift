import UIKit
import CloudKit

struct CharacterMetadata: Codable {
    let character: String
    let startTime: Double
    let isStressed: Bool
    let isLong: Bool
    let toneNumber: Int
    let pinyin: String
}

typealias LessonParagraphMetadata = [CharacterMetadata]

struct Lesson: Codable {
    let title: String
    let authorName: String
    let audioFile: URL
    let transcriptMetadata: [LessonParagraphMetadata]
}

extension Lesson {
    init?(record: CKRecord) {
        guard let lessonName = record["lessonName"] as? String else { return nil }
        guard let authorName = record["authorName"] as? String else { return nil }
        guard let characterData = record["annotatedTranscript"] as? Data else { return nil }
        guard let audioFile = record["audioFile"] as? CKAsset else { return nil }
        guard let fileUrl = audioFile.fileURL else { return nil }
        
        let newAudioUrl = FileManager.default.getDocumentsDirectory().appendingPathComponent(record.recordID.recordName)
        
        do {
            try FileManager.default.copyItem(at: fileUrl, to: newAudioUrl)
        } catch {
            print("Error copying file from \(fileUrl) to \(newAudioUrl)")
        }
        
        guard let characterMetadata: [LessonParagraphMetadata] = try? JSONDecoder().decode([LessonParagraphMetadata].self, from: characterData) else {
            return nil
        }
        
        self.init(title: lessonName, authorName: authorName, audioFile: newAudioUrl, transcriptMetadata: characterMetadata)
    }
}
