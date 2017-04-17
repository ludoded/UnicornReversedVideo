//
//  MovieConverter.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//


import AVFoundation
import UIKit

let kErrorDomain = "TimeLapseBuilder"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1

class MovieConverter: NSObject {
    let buffer: [CVPixelBuffer]
    let fps: Int32
    var videoWriter: AVAssetWriter?
    
    init(buffer: [CVPixelBuffer], fps: Int32) {
        self.buffer = buffer
        self.fps = fps
    }
    
    func build(_ progress: @escaping ((Progress) -> Void), success: @escaping ((URL) -> Void), failure: ((NSError) -> Void)) {
        var error: NSError?
        
        let firstPixelBuffer = buffer.first!
        let width = CVPixelBufferGetWidth(firstPixelBuffer)
        let height = CVPixelBufferGetHeight(firstPixelBuffer)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MergedVideo.mov"))
        
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}
        
        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }
        
        if let videoWriter = videoWriter {
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : AVVideoCodecH264,
                AVVideoWidthKey  : width,
                AVVideoHeightKey : height
            ]
            
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            
            let attr = CVBufferGetAttachments(firstPixelBuffer, .shouldPropagate) as! [String : Any]
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput,
                sourcePixelBufferAttributes: attr
            )
            
            assert(videoWriter.canAdd(videoWriterInput))
            videoWriterInput.expectsMediaDataInRealTime = true
            videoWriter.add(videoWriterInput)
            
            if videoWriter.startWriting() {
                videoWriter.startSession(atSourceTime: kCMTimeZero)
                assert(pixelBufferAdaptor.pixelBufferPool != nil)
                
                let media_queue = DispatchQueue(label: "mediaInputQueue")
                
                videoWriterInput.requestMediaDataWhenReady(on: media_queue) { [weak self] in
                    guard let welf = self else { return }
                    let frameDuration = CMTimeMake(1, welf.fps)
                    let currentProgress = Progress(totalUnitCount: Int64(welf.buffer.count))
                    
                    var frameCount: Int64 = 0
                    var remainingPhotoURLs = welf.buffer
                    
                    while !remainingPhotoURLs.isEmpty {
                        let nextPhotoURL = remainingPhotoURLs.remove(at: 0)
                        let lastFrameTime = CMTimeMake(frameCount, welf.fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        while !videoWriterInput.isReadyForMoreMediaData {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                        
                        pixelBufferAdaptor.append(nextPhotoURL, withPresentationTime: presentationTime)
                        
                        frameCount += 1
                        
                        currentProgress.completedUnitCount = frameCount
                        progress(currentProgress)
                    }
                    
                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        if error == nil {
                            success(videoOutputURL)
                        }
                        
                        welf.videoWriter = nil
                    }
                }
            } else {
                error = NSError(
                    domain: kErrorDomain,
                    code: kFailedToStartAssetWriterError,
                    userInfo: ["description": "AVAssetWriter failed to start writing"]
                )
            }
        }
        
        if let error = error {
            failure(error)
        }
    }
}
