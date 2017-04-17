//
//  CameraPresenter.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import Foundation

protocol CameraPresenterOutput: class {
    func displayCaptureSession()
    func displayProcessing()
    func displayCameraFinishRecording(viewModel: Camera.Record.ViewModel)
}

final class CameraPresenter {
    weak var output: CameraPresenterOutput!
    
    func presentCaptureSession() {
        output.displayCaptureSession()
    }
    
    func presentCaptureFinishedRecording(response: Camera.Record.Response) {
        let viewModel: Camera.Record.ViewModel
        
        if let error = response.error {
            viewModel = Camera.Record.ViewModel(title: "Error", message: error.localizedDescription)
        }
        else {
            viewModel = Camera.Record.ViewModel(title: "Success", message: "Saved to Gallery")
        }
        
        DispatchQueue.main.async {
            self.output.displayCameraFinishRecording(viewModel: viewModel)
        }
    }
    
    func presentProcessing() {
        DispatchQueue.main.async { self.output.displayProcessing() }
    }
}
