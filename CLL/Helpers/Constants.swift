//
//  Constants.swift
//  CustomLoginDemo
//
//  Created by Christopher Ching on 2019-07-23.
//  Copyright © 2019 Christopher Ching. All rights reserved.
//

import Foundation

struct Constants {
    
    struct Storyboard {
        
        static let studentHomeViewController = "StudentHomeVC"
        static let homeViewController = "HomeVC"
        static let navigationController = "NavigationController"
        static let teacherHomeViewController = "TeacherHomeVC"
        static let studentLessonsController = "StudentLessonsVC"
        static let studentAudioRecordsController = "StudentAudioRecordsVC"
        static let lessonSelectionViewController = "LessonSelectionViewController"
        static let teacherStudentsViewController = "TeacherStudentsVC"
        static let studentAudioFeedbackViewController = "StudentAudioFeedbackVC"
    }
    
    struct UserRole{
        static let student = 0
        static let teacher = 1
    }
    
    struct Passwords{
        static let RegisterAsTeacher = "CLL2019"
    }
    
}
