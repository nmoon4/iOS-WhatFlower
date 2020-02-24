//
//  WikiSearchManager.swift
//  WhatFlower
//
//  Created by Noel Moon on 2/21/20.
//  Copyright © 2020 Noel Moon. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol WikiManagerDelegate {
    func didUpdateWiki(_ wikiManager: WikiManager, wikiModel: WikiModel)
    
    func didFailWithError(error: Error)
}

struct WikiManager {
    
    var delegate: WikiManagerDelegate?
    
    func fetchWikiInfo(flowerName: String) {
        let wikiURL = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|pageimages&redirects=1&exintro=&explaintext=&indexpageids=&pithumbsize=500"
        
        let flower = flowerName
        
        let urlString = "\(wikiURL)&titles=\(flower)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        performRequest(with: urlString)
    }
    
    func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                
                if let safeData = data {
                    //let dataString = String(data: safeData, encoding: .utf8)
                    //print(dataString)
                    
                    if let wiki = self.parseJSON(safeData) {
                        
                        self.delegate?.didUpdateWiki(self, wikiModel: wiki)
                    }
                }
            }
            
            task.resume()
        }
        
    }
    
    func parseJSON(_ wikiData: Data) -> WikiModel? {
        do {
            let flowerJSON = try JSON(data: wikiData)
            
            let pageId = flowerJSON["query"]["pageids"][0].stringValue
            
            let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
            let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
            
            let wikiModel = WikiModel(description: flowerDescription, flowerImageURL: flowerImageURL)

            return wikiModel
            
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }

    }
    
}
