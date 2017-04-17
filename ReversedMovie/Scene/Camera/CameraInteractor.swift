//
//  CameraInteractor.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraInteractorOutput {
    func presentCaptureSession()
    func presentProcessing()
    func presentCaptureFinishedRecording(response: Camera.Record.Response)
}

final class CameraInteractor: NSObject {
    var output: CameraInteractorOutput!
    var captureSession: AVCaptureSession!
    var dataOutput: AVCaptureVideoDataOutput!
    var progress: ((Float) -> ())!
    
    fileprivate let totalFrames: Int = 120
    fileprivate var recordShallStart: Bool = false
    fileprivate var buffers = [CVImageBuffer]()
    fileprivate var converter: MovieConverter!
    
    func prepareSession() {
        captureSession = AVCaptureSession()
        
        let input = try? AVCaptureDeviceInput(device: connectedDevice())
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        captureSession.startRunning()
        
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
           captureSession.addOutput(dataOutput)
        }
        captureSession.commitConfiguration()
        
        let queue: DispatchQueue = DispatchQueue(label: "VideoOutputQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        dataOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
        
        output.presentCaptureSession()
    }
    
    func startRecord() {
        recordShallStart = true
    }
    
    fileprivate func connectedDevice() -> AVCaptureDevice! {
        if #available(iOS 10.0, *) {
            return AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
        }
        else {
            return AVCaptureDevice.devices()
                .map { $0 as! AVCaptureDevice }
                .filter { $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.back }.first! as AVCaptureDevice
        }
    }
    
    fileprivate func merge() {
        output.presentProcessing()
        
        var requestBuffer = buffers
        buffers[0 ... buffers.count - 2].reversed().forEach({ requestBuffer.append($0.deepcopy()) })
        
        converter = MovieConverter(buffer: requestBuffer)
        
        converter.build({ (_) in },
                        success: { [weak self] (url) in
                            self?.passResult(url: url, error: nil)
        }) { [weak self] (error) in
            self?.passResult(url: nil, error: error)
        }
        
    }
    
    fileprivate func passResult(url: URL?, error: Error?) {
        buffers.removeAll()
        
        saveToCameraRoll(url: url) { [weak self] (saveError) in
            let response: Camera.Record.Response
            if saveError == nil { response = Camera.Record.Response(url: url, error: error) }
            else { response = Camera.Record.Response(url: url, error: saveError) }
            
            self?.output.presentCaptureFinishedRecording(response: response)
        }
    }
    
    fileprivate func saveToCameraRoll(url: URL?, callback: @escaping (_ error: Error?) -> ()) {
        guard let url = url else { callback(nil); return }
        PhotoAlbum.shared.save(url) { (success, error) in
            callback(error)
        }
    }
}

extension CameraInteractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let cvBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if captureOutput is AVCaptureVideoDataOutput, recordShallStart {
            let copiedCvBuf = cvBuf.deepcopy()
            buffers.append(copiedCvBuf)
            progress?(Float(buffers.count) / Float(totalFrames))
            
            if buffers.count >= totalFrames {
                recordShallStart = false
                merge()
            }
        }
    }
}
