//
//  ViewController.swift
//  Loafy
//
//  Created by Dei on 10.02.2020.
//  Copyright © 2020 Solden Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: - Private Properties
    
    @IBOutlet private weak var previewImageView: NSImageView!
    @IBOutlet private weak var customView: NSView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewImageView.imageScaling = .scaleProportionallyUpOrDown
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        setPreviewImage()
    }
    
    override var representedObject: Any? {
        didSet { }
    }
    
    // MARK: - Private Methods
    
    private func setPreviewImage() {
        let dashPattern: [CGFloat] = [24, 10]
        let dashWidth: CGFloat = 8
        let dashColor = NSColor.red
        let fillColor = NSColor.white
        
        let screens = NSScreen.screens
        guard let minX = (screens.min { $0.frame.minX < $1.frame.minX })?.frame.minX,
            let minY = (screens.min { $0.frame.minY < $1.frame.minY })?.frame.minY,
            let maxX = (screens.max { $0.frame.maxX < $1.frame.maxX })?.frame.maxX,
            let maxY = (screens.max { $0.frame.maxY < $1.frame.maxY })?.frame.maxY else {
                return
        }
        
        let totalRect = CGRect(x: 0, y: 0, width: maxX - minX, height: maxY - minY)
        let totalRectWithDashGap = CGRect(x: 0,
                                          y: 0,
                                          width: totalRect.width + dashWidth,
                                          height: totalRect.height + dashWidth)
        
        print(totalRectWithDashGap)
        print("\n\(NSScreen.screens.reduce("") { $0 + $1.frame.debugDescription + ";\n" })")
        
        let previewImage = NSImage(size: totalRectWithDashGap.size)
        previewImage.lockFocus()
        
        fillColor.setFill()
        
        for screen in screens {
            let screenRect = CGRect(x: screen.frame.minX + dashWidth / 2,
                                    y: screen.frame.minY + dashWidth / 2,
                                    width: screen.frame.width - dashWidth,
                                    height: screen.frame.height - dashWidth)
            let screenPath = NSBezierPath(rect: screenRect)
            dashColor.setStroke()
            screenPath.lineWidth = dashWidth
            screenPath.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            
            screenRect.fill()
            screenPath.stroke()
        }
        
        previewImage.unlockFocus()
        
        print(previewImage.size)
        
        previewImageView.image = previewImage
    }
    
    
}

