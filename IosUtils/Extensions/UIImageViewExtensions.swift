//
//  UIButtonExtensions.swift
//  Networkamp
//
//  Created by woko on 17/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation
import UIKit

public extension UIImageView {
    public var setColor:UIColor {
        set {
            let origImage = self.image
            let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
            self.image = tintedImage
            tintColor = newValue
        }
        get {
            return tintColor
        }
    }
}
