//
//  Extension.swift
//  LevelGetter
//
//  Created by Dayson Dong on 2019-10-04.
//  Copyright © 2019 Dayson Dong. All rights reserved.
//

import Foundation

extension String {

    func videoLink() -> String?
    {
        let pattern = "https://videos.bodybuilding.com/video/mp4/[0-9]+/[0-9a-z]+.mp4"

        if let res = self.range(of: pattern, options:[.regularExpression, .caseInsensitive]) {
            let link = String(self[res])
            return link
        }
        else {
            return nil
        }
    }

    func descriptionStep() -> [String]
    {

        let detailPattern =  "<li class=\"ExDetail-descriptionStep\">[a-z0-9 ,.]{1,}"

        if let regex = try? NSRegularExpression(pattern: detailPattern, options: .caseInsensitive)
        {
            let string = self as NSString

            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                String(string.substring(with: $0.range).dropFirst("<li class=\"ExDetail-descriptionStep\">".count))
            }
        }

        return []
    }

    func level() -> String? {

        let pattern = "level:[\n]*[ ]+[a-zA-Z]+[\n]"
        let res = self.range(of: pattern, options:[.regularExpression, .caseInsensitive])
        if res != nil {
            let trimmed = self[res!].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "Level:", with: "").replacingOccurrences(of: "\n", with: "")
            return trimmed
        } else {
            return nil
        }
    }
    
//    func largeImageLink() -> String? {
//       
//        if let lastMIndex = self.lastIndex(of: "m") {
//            let link = self.replacingCharacters(in: lastMIndex...lastMIndex, with: "l")
//            return link
//        } else {
//            return nil
//        }
//    }
    
    func detailImageLinks() -> [String] {
        let imagePattern = "https://www.bodybuilding.com/exercises/exerciseImages/sequences/[0-9]+/Male/l/[0-9_]+.jpg"
        var links: [String] = []
        if let regex = try? NSRegularExpression(pattern: imagePattern, options: .caseInsensitive)
        {
            let string = self as NSString
            
            regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).forEach { (res) in
                if !links.contains(string.substring(with: res.range)) {
                    links.append(string.substring(with: res.range))
                }
            }

//            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
//                String(string.substring(with: $0.range))
//            }
        }

        return links
    }
    
    
}
