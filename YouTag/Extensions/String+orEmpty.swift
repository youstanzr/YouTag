//
//  String+orEmpty.swift
//  YouTag
//
//  Created by spooky on 5/14/20.
//  Copyright © 2020 Youstanzr. All rights reserved.
//

import Foundation

extension Optional where Wrapped == String {
    
    var orEmpty: String {
        return self ?? ""
    }
}
