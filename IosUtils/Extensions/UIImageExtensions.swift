//
//  UIImageExtensions.swift
//  Networkamp
//
//  Created by woko on 17/07/2018.
//  Copyright © 2018 Pandastic Games. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    public func resizeImage(_ scale:Float) -> UIImage {
        let size = self.size
        let newSize = CGSize(width: size.width * CGFloat(scale), height: size.height * CGFloat(scale))
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    public func tint(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // flip the image
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -self.size.height)
        
        // multiply blend mode
        context.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        
        // create UIImage
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        UIGraphicsEndImageContext()
        
        return newImage.resizableImage(withCapInsets: self.capInsets, resizingMode: self.resizingMode)
    }
        
}
