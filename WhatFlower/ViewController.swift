//
//  ViewController.swift
//  WhatFlower
//
//  Created by Noel Moon on 2/18/20.
//  Copyright © 2020 Noel Moon. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    var wikiManager = WikiManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        wikiManager.delegate = self
        
        // testing
        self.wikiManager.fetchWikiInfo(flowerName: "Cyclamen")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            //imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("could not convert UIImage to CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("loading CoreML Model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            
            //print(results[0])
            
            if let firstResult = results.first {
                let confidence = String(format: "%.2f", firstResult.confidence)
                
                self.navigationItem.title = "\(firstResult.identifier.capitalized) - \(confidence)"
                
                self.wikiManager.fetchWikiInfo(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    

    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
}

//MARK: - WikiManagerDelegate

extension ViewController: WikiManagerDelegate {
    func didUpdateWiki(_ wikiManager: WikiManager, wikiModel: WikiModel) {
        
        DispatchQueue.main.async {
            self.textLabel.text = wikiModel.description
            print(wikiModel.flowerImageURL)
            self.imageView.sd_setImage(with: URL(string: wikiModel.flowerImageURL))
        }
    }
    
    func didFailWithError(error: Error) {
        print(error)
    }
}
