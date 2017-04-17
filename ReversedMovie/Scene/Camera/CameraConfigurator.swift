//
//  CameraConfigurator.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import UIKit

extension CameraViewController: CameraPresenterOutput {}

extension CameraInteractor: CameraViewControllerOutput {}

extension CameraPresenter: CameraInteractorOutput {}

final class CameraConfigurator {
    static let shared = CameraConfigurator()
    
    private init() {}
    
    func configure(viewController: CameraViewController) {
        let presenter = CameraPresenter()
        presenter.output = viewController
        
        let interactor = CameraInteractor()
        interactor.output = presenter
        
        viewController.output = interactor
    }
}
