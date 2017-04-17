//
//  CameraViewController.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraViewControllerOutput {
    var captureSession: AVCaptureSession! { get }
    var progress: ((Float) -> ())! { get set }
    
    func prepareSession()
    func startRecord()
}

final class CameraViewController: UIViewController {
    var preview: AVCaptureVideoPreviewLayer!
    var output: CameraViewControllerOutput!
    
    @IBOutlet weak var sessionLayer: UIView!
    @IBOutlet weak var captureKnob: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activity: UIView!
    
    @IBAction func startRecord(sender: UIButton) {
        sender.isUserInteractionEnabled = false
        progressView.alpha = 1.0
        output.startRecord()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        CameraConfigurator.shared.configure(viewController: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = sessionLayer.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSession()
        
        /// MARK: Setup Progress
        output.progress = { [weak self] progress in
            DispatchQueue.main.async { self?.progressView.progress = progress }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    func prepareSession() {
        output.prepareSession()
    }
    
    /// MARK: Presenter 
    func displayCaptureSession() {
        preview = AVCaptureVideoPreviewLayer(session: output.captureSession)
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.connection.videoOrientation = .portrait
        sessionLayer.layer.addSublayer(preview)
    }
    
    func displayCameraFinishRecording(viewModel: Camera.Record.ViewModel) {
        captureKnob.isUserInteractionEnabled = true
        progressView.alpha = 0.0
        activity.isHidden = true
        
        let alert = UIAlertController(title: viewModel.title, message: viewModel.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        navigationController?.present(alert, animated: true, completion: nil)
    }
    
    func displayProcessing() {
        activity.isHidden = false
    }
}
