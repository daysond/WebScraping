//
//  main.swift
//  LevelGetter
//
//  Created by Dayson Dong on 2019-10-03.
//  Copyright © 2019 Dayson Dong. All rights reserved.
//

import Foundation
import SwiftSoup

var exercises: [Exercise] = []
let path = "/Users/dsn/desktop/BBData/cardio.json"
let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
var succeedCount = 0

func encodeData() {
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(exercises)
    //    let s1 = String(data: data, encoding: .utf8)
    let path = "/Users/dsn/desktop/BBData/cardio_with_details.json"
    let urlPath = URL(fileURLWithPath: path)
    do {
        try data.write(to: urlPath)
        print("File saved!")
    } catch  {
        print("failed to write file \(error.localizedDescription)")
    }
    
}

func parseTargetText(_ t: String) -> [String: String]{
    //                let cp = t.contains("Caution:")
    //                let vp = t.contains("Variations:")
    let rangeV = t.range(of: "Variations:")
    let rangeC = t.range(of: "Caution:")
    var res: [String: String] = [:]
    if rangeV != nil  {
        let variations = t[rangeV!.upperBound...]
        res["variations"] = "\(variations)"
//        print("Got variants!")
    }
    if rangeC != nil {
        if rangeV != nil {
            let caution = t[rangeC!.upperBound..<rangeV!.lowerBound]
            res["caution"] = "\(caution)"
        } else {
            let caution = t[rangeC!.upperBound...]
            res["caution"] = "\(caution)"
        }
    }
    
    return res
}

func parseHTML(_ html: String, for exercise: Exercise) {
    
    var targetText: String?
    var steps: [String] = []
    
    if let level = html.level() {
        exercise.level = level
        succeedCount = succeedCount + 1
//        print("Succeed! \(exercise.name) level: \(exercise.level)")
    } else {
        exercise.level = "N/A"
        print("Failed.")
    }
    
    do {
        let doc: Document = try SwiftSoup.parse(html)

        let div = try doc.select("div").array()
        for element in div {
            let name = try element.className()
            if name == "grid-8 grid-12-s grid-12-m" {
                targetText = try? element.text()
                
                try element.select("ol").select("li").array().forEach({ (step) in
                    try? steps.append(step.text())
                })
            }
        }
        
    } catch Exception.Error(type: let type, Message: let message) {
        print(type)
        print(message)
    } catch {
        print(error.localizedDescription)
    }
    
    if steps.count != 0{
        exercise.steps = steps
    } else {
        print("NO STEP FOUND FOR EXERCISE \(exercise.name) at url \(exercise.mainURL)")
    }
    
    

    let cautionAndVar = parseTargetText(targetText!)
    
    if let caution = cautionAndVar["caution"] {
        exercise.caution = caution
    }
    if let variations = cautionAndVar["variations"] {
        exercise.variations = variations
    }
    
}

if let exercisesArray = jsonResult as? [[String: Any]]  {
    
    
    exercisesArray.forEach { (ex) in
        
        if let exercise = Exercise(withJSONResult: ex) {
            if  !exercises.contains(exercise) {
                exercises.append(exercise)
            }
        }
    }
    
    print("Found \(exercises.count) exercises\n")
    
    if exercises.count != 0 {
        print("About to get HTML of \(exercises.count) exercises")
        
        let group = DispatchGroup()
        exercises.forEach { (ex) in
            group.enter()
            if let url = URL(string: ex.mainURL) {
                let request = URLRequest(url: url)
                
                DispatchQueue.main.async {
                    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                        
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        guard response != nil else {
                            print("no response")
                            return
                        }
                        
                        guard let data = data else {
                            print("no data")
                            return
                        }
                        //                    print("getting \(index)/\(exercises.count)")
                        if let html  = String(data: data, encoding: .utf8) {
                            parseHTML(html, for: ex)
                            
                        }
                        group.leave()
                    }
                    sleep(1)
                    task.resume()
                }
            } else {
                print("NO URL of \(ex.name)")
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("Got \(succeedCount) out of \(exercises.count)")
            encodeData()
            exit(EXIT_SUCCESS)
        }
        dispatchMain()
    }
} else {
    print("no json result")
    exit(EXIT_FAILURE)
}





//    func parseHTML() {
//        
//        do {
//            
//            guard let html = html else { print("NO HTML!!!"); return }
//            let doc: Document = try SwiftSoup.parse(html)
//            var targetText: String?
//            var steps: [String] = []
//            let div = try doc.select("div").array()
//                       for element in div {
//                           let name = try element.className()
//                           if name == "grid-8 grid-12-s grid-12-m" {
//                            targetText = try? element.text()
//                            
//                            try element.select("ol").select("li").array().forEach({ (step) in
//                                try? steps.append(step.text())
//                            })
//                           }
//                       }
//            
//            
//            
//            func parseTargetText(_ t: String) {
////                let cp = t.contains("Caution:")
////                let vp = t.contains("Variations:")
//                let rangeV = t.range(of: "Variations:")
//                let rangeC = t.range(of: "Caution:")
//                if rangeV != nil  {
//                    let variations = t[rangeV!.upperBound...]
//                    print(variations)
//                }
//                if rangeC != nil {
//                    if rangeV != nil {
//                        let str = t[rangeC!.upperBound..<rangeV!.lowerBound]
//                        print(str)
//                    } else {
//                        let str = t[rangeC!.upperBound...]
//                        print(str)
//                    }
//                }
//            }
//            
//            parseTargetText(targetText!)
//            steps.forEach { (s) in
//                print(s)
//            }
//            
//        } catch Exception.Error(type: let type, Message: let message) {
//            print(type)
//            print(message)
//        } catch {
//            print(error.localizedDescription)
//        }
//        
//    }
//    
//    func getHTML() {
//        
//        if let url = URL(string: link) {
//            let request = URLRequest(url: url)
//            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//                guard error == nil else {
//                    print(error!.localizedDescription)
//                    return
//                }
//                guard response != nil else {
//                    print("no response")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("no data")
//                    return
//                }
//                if let result  = String(data: data, encoding: .utf8) {
//                    self.html = result
//                    self.outputFile(str: result)
//                    print("Got HTML !")
//                    self.parseHTML()
//                    
//                }
//            }
//            task.resume()
//        }
//        
//    }
//
