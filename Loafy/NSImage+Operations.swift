//
//  NSImage+Scale.swift
//  Loafy
//
//  Created by Dei on 10.02.2020.
//  Copyright © 2020 Solden Inc. All rights reserved.
//

import Cocoa

extension NSImage {
    
    func trim(to rect: CGRect) -> NSImage {
        let trimedImage = NSImage(size: rect.size)
        trimedImage.lockFocus()
        
        let destinationRect = CGRect(origin: .zero, size: trimedImage.size)
        self.draw(in: destinationRect, from: rect, operation: .copy, fraction: 1.0)
        
        trimedImage.unlockFocus()
        return trimedImage
    }
    
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
        
        cropRect.origin.x = floor(sourceSize.width / 2 - cropRect.size.width / 2)
        cropRect.origin.y = floor(sourceSize.height / 2 - cropRect.size.height / 2)
        
        targetImage.lockFocus()
        
        self.draw(in: targetFrame,
                  from: cropRect,
                  operation: NSCompositingOperation.copy,
                  fraction: 1.0)
        
        targetImage.unlockFocus()
        
        return targetImage
    }
    
}
