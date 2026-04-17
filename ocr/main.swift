//
//  main.swift
//  OCR
//
//  Created by Marcus Schappi on 17/5/21, 11:36 am
//

import Foundation
import CoreImage
import Cocoa
import Vision
import ScreenCapture
import ArgumentParserKit


var joiner = "\n"
var bigSur = false;

if #available(macOS 11, *) {
    bigSur = true;
}

func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
    let context = CIContext(options: nil)
    if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
        return cgImage
    }
    return nil
}

func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
        return
    }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    // Process the recognized strings.
    let joined = recognizedStrings.joined(separator: joiner)
    print(joined)
    
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(joined, forType: .string)
    
}

func detectText(fileName : URL) -> [CIFeature]? {
    if let ciImage = CIImage(contentsOf: fileName){
        guard let img = convertCIImageToCGImage(inputImage: ciImage) else { return nil}
      
        let requestHandler = VNImageRequestHandler(cgImage: img)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLanguages = recognitionLanguages
       
        
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
}
    return nil
}



var recognitionLanguages = ["en-US"]

do {


    let arguments = Array(CommandLine.arguments.dropFirst())

    let parser = ArgumentParser(usage: "<options>", overview: "macOCR is a command line app that enables you to turn any text on your screen into text on your clipboard")

    let listLanguagesOption = parser.add(option: "--list-languages", kind: Bool.self, usage: "List supported OCR languages")
    let rectOption = parser.add(option: "--rect", shortName: "-R", kind: String.self, usage: "Capture specific region: x,y,width,height (no interactive selection)")
    let inputFileOption = parser.add(option: "--input", shortName: "-i", kind: String.self, usage: "Use image file instead of screen capture")
    let saveImageOption = parser.add(option: "--save-image", shortName: "-s", kind: String.self, usage: "Save captured screenshot to specified path")

    var rectValues: (x: Int, y: Int, w: Int, h: Int)? = nil
    var inputFile: String? = nil
    var saveImagePath: String? = nil

    if(bigSur){
        let languageOption = parser.add(option: "--language", shortName: "-l", kind: String.self, usage: "Set Language (Supports Big Sur and Above)")


        let parsedArguments = try parser.parse(arguments)

        // Check if user wants to list languages
        if parsedArguments.get(listLanguagesOption) == true {
            if #available(macOS 11.0, *) {
                let languages = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2)
                print("Supported languages (accurate):")
                for lang in languages {
                    print("  \(lang)")
                }
            } else {
                print("en-US (language detection requires macOS 11.0+)")
            }
            exit(EXIT_SUCCESS)
        }

        // Parse rect option
        if let rectString = parsedArguments.get(rectOption) {
            let parts = rectString.split(separator: ",").compactMap { Int($0) }
            if parts.count == 4 {
                rectValues = (x: parts[0], y: parts[1], w: parts[2], h: parts[3])
            } else {
                print("Error: --rect requires format x,y,width,height (e.g., --rect 100,100,500,300)")
                exit(EXIT_FAILURE)
            }
        }

        // Parse input file option
        inputFile = parsedArguments.get(inputFileOption)

        // Parse save image option
        saveImagePath = parsedArguments.get(saveImageOption)

        let language = parsedArguments.get(languageOption)

        if (language ?? "").isEmpty{

        }else{
            recognitionLanguages.insert(language!, at: 0)
        }
    } else {
        let parsedArguments = try parser.parse(arguments)
        if parsedArguments.get(listLanguagesOption) == true {
            print("en-US (language detection requires macOS 11.0+)")
            exit(EXIT_SUCCESS)
        }

        // Parse rect option
        if let rectString = parsedArguments.get(rectOption) {
            let parts = rectString.split(separator: ",").compactMap { Int($0) }
            if parts.count == 4 {
                rectValues = (x: parts[0], y: parts[1], w: parts[2], h: parts[3])
            } else {
                print("Error: --rect requires format x,y,width,height (e.g., --rect 100,100,500,300)")
                exit(EXIT_FAILURE)
            }
        }

        // Parse input file option
        inputFile = parsedArguments.get(inputFileOption)

        // Parse save image option
        saveImagePath = parsedArguments.get(saveImageOption)
    }

    // Determine the image to process
    var imageURL: URL

    if let input = inputFile {
        // Use provided image file
        let inputPath = (input as NSString).expandingTildeInPath
        imageURL = URL(fileURLWithPath: inputPath)
        if !FileManager.default.fileExists(atPath: imageURL.path) {
            print("Error: Input file does not exist: \(input)")
            exit(EXIT_FAILURE)
        }
    } else {
        // Capture screen region
        let tempPath = "/tmp/ocr.png"
        if let rect = rectValues {
            let _ = ScreenCapture.captureRect(destination: tempPath, x: rect.x, y: rect.y, width: rect.w, height: rect.h)
        } else {
            let _ = ScreenCapture.captureRegion(destination: tempPath)
        }
        imageURL = URL(fileURLWithPath: tempPath)

        // Save image if requested
        if let savePath = saveImagePath {
            let expandedPath = (savePath as NSString).expandingTildeInPath
            do {
                try FileManager.default.copyItem(atPath: tempPath, toPath: expandedPath)
            } catch {
                print("Warning: Could not save image to \(savePath): \(error.localizedDescription)")
            }
        }
    }

    if let features = detectText(fileName: imageURL), !features.isEmpty{}

} catch {
    // handle parsing error
}

exit(EXIT_SUCCESS)
