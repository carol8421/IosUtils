//
//  UIButtonExtensions.swift
//  Networkamp
//
//  Created by woko on 17/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation
import UIKit

public extension UIButton {
    public var setColor:UIColor {
        set {
            let origImage = self.image(for: .normal)
            let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
            setImage(tintedImage, for: .normal)
            tintColor = newValue
        }
        get {
            return tintColor
        }
    }
}
