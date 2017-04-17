//
//  CameraModel.swift
//  ReversedMovie
//
//  Created by Haik Ampardjian on 4/17/17.
//  Copyright © 2017 Unicorn. All rights reserved.
//

import Foundation

struct Camera {
    struct Record {
        struct Response {
            let url: URL?
            let error: Error?
        }
        
        struct ViewModel {
            let title: String
            let message: String
        }
    }
}
