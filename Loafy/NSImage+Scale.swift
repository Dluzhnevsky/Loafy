//
//  NSImage+Scale.swift
//  Loafy
//
//  Created by Dei on 10.02.2020.
//  Copyright © 2020 Solden Inc. All rights reserved.
//

import Cocoa

extension NSImage {
    
    func resizeToFit(_ size: CGSize) -> NSImage {
        let targetFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let targetImage = NSImage(size: size)
        
        let sourceSize = self.size
        let ratioW = size.width / sourceSize.width
        let ratioH = size.height / sourceSize.height
        
        var cropRect = NSZeroRect
        if (ratioH >= ratioW) {
            cropRect.size.width = floor(size.width / ratioH)
            cropRect.size.height = sourceSize.height
        }
        else {
            cropRect.size.width = sourceSize.width
            cropRect.size.height = floor(size.height / ratioW)
        }
        
        cropRect.origin.x = floor(sourceSize.width - cropRect.size.width / 2)
        cropRect.origin.y = floor(sourceSize.height - cropRect.size.height / 2)
        
        targetImage.lockFocus()
        
        self.draw(in: targetFrame,
                  from: cropRect,
                  operation: NSCompositingOperation.copy,
                  fraction: 1.0)
        
        targetImage.unlockFocus()
        
        return targetImage
    }
    
}
