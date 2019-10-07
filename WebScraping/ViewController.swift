//
//  ViewController.swift
//  WebScraping
//
//  Created by Dayson Dong on 2019-10-04.
//  Copyright © 2019 Dayson Dong. All rights reserved.
//

import UIKit
import SwiftSoup

class ViewController: UIViewController {
    
    let fileNames = ["cardio.json", "All_Exercises.json", "compound.json", "isolation.json", "Strength.json", "Stretching.json"]
    var currentFileIndex = 0
    var exercises: [Exercise] = []
    //    let path = "/Users/dsn/desktop/BBData/cardio.json"
    var levelCount = 0
    var stepCount = 0
    var cautionCount = 0
    var variationsCount = 0
    var videoLinkCount = 0
    var largeImageCount = 0
    var guideCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        scrapeNext()
            

        
    }
    
    func scrapeNext() {
        guard currentFileIndex < fileNames.count else { print("no more files"); return }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let urlPath = paths[0].appendingPathComponent(fileNames[currentFileIndex])

        getJSON(at: urlPath)

        guard exercises.count != 0 else { return }

        getHTML()
    }
    
    //MARK: FIRST: get json and populate exercises
    
    func getJSON(at path: URL)  {
        print("Parsing file \(fileNames[currentFileIndex])")
        do {
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let exercisesArray = jsonResult as? [[String: Any]] {
                exercises.removeAll()
                print("Cleared exercises. Count is now \(exercises.count).")
                exercisesArray.forEach { (ex) in
                    if let exercise = Exercise(withJSONResult: ex) {
                        if  !exercises.contains(exercise) {
                            exercises.append(exercise)
                        }
                    }
                }
                print("Found \(exercises.count) exercises\n")
            } else {
                print(" NO EXERCISES FOUND")
                return
            }
            
        } catch  {
            print(error.localizedDescription)
            return
        }
    }
    
    //MARK: SECOND: GET html
    
    func getHTML()  {
        
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
                        
                        if let html  = String(data: data, encoding: .utf8) {
                            self.parseHTML(html, for: ex)
                            print("Finished exercise \(ex.name)")
                        }
                        group.leave()
                    }
                    if self.exercises.count > 100 {
                        sleep(1)
                    }

                    task.resume()
                }
            } else {
                print("NO URL of \(ex.name)")
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("Got \(self.levelCount) level out of \(self.exercises.count)\nGot \(self.stepCount) step.\nGot \(self.variationsCount) vs.\nGot \(self.cautionCount) cs.\nGot \(self.largeImageCount) large image.\nGot \(self.videoLinkCount) video.\nGot \(self.guideCount) guide.")
            self.encodeData()
        }
//        dispatchMain()
        
    }
    
    //MARK: PARSE HTML
    
    func parseTargetText(_ t: String) -> [String: String]{
        
        let rangeV = t.range(of: "Variations:")
        let rangeC = t.range(of: "Caution:")
        var res: [String: String] = [:]
        
        if rangeV != nil && rangeC != nil  {
            // variations first then caution
            if rangeV!.upperBound < rangeC!.upperBound {
                let variations = t[rangeV!.upperBound..<rangeC!.lowerBound]
                res["variations"] = "\(variations)"
                let caution = t[rangeC!.upperBound...]
                res["caution"] = "\(caution)"
                variationsCount = variationsCount + 1
                cautionCount = cautionCount + 1
                return res
            } else {
                //caution first then variations
                let caution = t[rangeC!.upperBound..<rangeV!.lowerBound]
                res["caution"] = "\(caution)"
                cautionCount = cautionCount + 1
                let variations = t[rangeV!.upperBound...]
                res["variations"] = "\(variations)"
                variationsCount = variationsCount + 1
                return res
            }
        }
        if rangeV != nil  {
            let variations = t[rangeV!.upperBound...]
            res["variations"] = "\(variations)"
            variationsCount = variationsCount + 1
        }
        if rangeC != nil {
            let caution = t[rangeC!.upperBound...]
            res["caution"] = "\(caution)"
            cautionCount = cautionCount + 1
        }
        
        return res
    }
    
    func parseHTML(_ html: String, for exercise: Exercise) {
        
        var targetText: String?
        var steps: [String] = []
        
        if let level = html.level() {
            exercise.level = level
            levelCount = levelCount + 1
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
                
                if name == "grid-4 grid-12-s grid-12-m" {
                    let img = try element.select("img")
                    let link = try img.attr("src")
                    
                    exercise.guideImageURL = link
                    guideCount = guideCount + 1
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
            stepCount = stepCount + 1
        } else {
            print("NO STEP FOUND FOR EXERCISE \(exercise.name) at url \(exercise.mainURL)")
        }
        
        
        
        let cautionAndVar = parseTargetText(targetText!)
        
        if let caution = cautionAndVar["caution"] {
            exercise.caution = caution
            print("Got caution for exercise at \(exercise.mainURL)")
        }
        if let variations = cautionAndVar["variations"] {
            exercise.variations = variations
            print("Got variations for exercise at \(exercise.mainURL)")
        }
        
        if let videoLink = html.videoLink() {
            exercise.videoLink = videoLink
            videoLinkCount = videoLinkCount + 1
        } else {
            print("No video link found for exercise \(exercise.mainURL)")
        }
        
        if html.detailImageLinks().count != 0 {
            exercise.largeImageURLs = html.detailImageLinks()
            largeImageCount = largeImageCount + 1
        } else {
            print("NO large image found for exercise \(exercise.mainURL)")
        }
        
        if exercise.guideImageURL == "" {
            print("NO GUIDE FOR exercose \(exercise.mainURL)")
        }
        
    }
    
    //MARK: ENCODE DATA
    func encodeData() {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(exercises)
        //    let s1 = String(data: data, encoding: .utf8)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileName = fileNames[currentFileIndex]
        let urlPath = paths[0].appendingPathComponent("\(fileName)_with_details.json")
        do {
            try data.write(to: urlPath)
            print("File saved!")
        } catch  {
            print("failed to write file \(error.localizedDescription)")
        }
        currentFileIndex = currentFileIndex + 1
        scrapeNext()
        
    }
    
    
//    func outputFile(str: String) {
//
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let urlPath = paths[0].appendingPathComponent("html.html")
//        do {
//            try str.write(to: urlPath, atomically: false, encoding: .utf8)
//            print("File saved!")
//        } catch  {
//            print("failed to write file \(error.localizedDescription)")
//        }
//
//    }
    
    
}

