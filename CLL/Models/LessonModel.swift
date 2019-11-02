import Foundation
import CloudKit
import Crashlytics

class LessonModel {

    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    let LessonType = "Lesson"
    
    static let sharedInstance = LessonModel()
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    func saveLesson(_ lesson: Lesson, completion: @escaping (_ error: Error?) -> ()) {
        let newLesson = CKRecord(recordType: LessonType)
        
        newLesson["authorName"] = lesson.authorName
        newLesson["lessonName"] = lesson.title
        newLesson["audioFile"] = CKAsset(fileURL: lesson.audioFile)
        
        let encodedMetadata = try? JSONEncoder().encode(lesson.transcriptMetadata)
        newLesson["annotatedTranscript"] = encodedMetadata
        
        publicDB.save(newLesson) { savedRecord, error in
            defer {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
            
            if let error = error {
                print("Error saving lesson record: \(error.localizedDescription)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Situation": "Attempting to save lesson record to CloudKit", "lesson": lesson, "errorDescription": error.localizedDescription])
                return
            }
            if let record = savedRecord {
                print("Successfully saved lesson record: ", record)

            }
        }
    }
    
    func fetchAllLessons(completion: @escaping (_ lessons: [Lesson], _ error: Error?) -> ()) {
        let query = CKQuery(recordType: LessonType, predicate: NSPredicate(value: true))
        
        publicDB.perform(query, inZoneWith: nil) { results, error in
            
            var lessons = [Lesson]()
            defer {
                DispatchQueue.main.async {
                    completion(lessons, error)
                }
            }

            if let error = error {
                print("Error fetching all lessons: \(error.localizedDescription)")
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["Situation": "Attempting to fetch all lesson records from CloudKit", "errorDescription": error.localizedDescription])

                return
            }
            
            if let results = results {
                //print("Successfully fetched all lesson records: ", results)
                lessons = results.compactMap { record in
                    return Lesson(record: record)
                }
            }
            
        }
    }
    
}
