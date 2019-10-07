//
//  Exercises.swift
//  LevelGetter
//
//  Created by Dayson Dong on 2019-10-04.
//  Copyright © 2019 Dayson Dong. All rights reserved.
//

import Foundation

class Exercise: Codable {
    
    let imageURLs: [String]
    let mainURL: String
    let name: String
    let equipmentType: String
    let muscleTargeted: String
    let rating: Decimal
    var level: String = "NA"
    var steps: [String] = []
    var caution: String = ""
    var variations: String = ""
    var videoLink: String = ""
    var largeImageURLs: [String] = []
    var guideImageURL: String = ""
    
    init?(withJSONResult json: [String: Any]) {
        guard let imageLinkOne = json["Image_URL_One"] as? String else { print("init one failed"); return nil }
        guard let imageLinkTwo = json["Image_URL_Two"] as? String else { print("init two failed"); return nil }
        guard let url = json["URL"] as? String else { print("init url failed"); return nil }
        guard let equiment = json["Equipment_Type"] as? String else { print("init equi failed"); return nil }
        guard let muscle = json["Muscle_Targeted"] as? String else { print("init mus failed"); return nil }
        guard let name = json["Exercise_Name"] as? String else { print("init name failed"); return nil }
        if (json["Rating"] as? String) != nil {
            self.rating = 0
        } else if let rating = json["Rating"] as? Double {
            self.rating = Decimal.init(floatLiteral: rating)
        } else {
            return nil
        }
        self.imageURLs = [imageLinkOne, imageLinkTwo]
        self.mainURL = url
        self.name = name
        self.equipmentType = equiment
        self.muscleTargeted = muscle
        
    }
    
    
}

extension Exercise: Comparable {
    static func < (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.rating < rhs.rating
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.name == rhs.name
    }
}
