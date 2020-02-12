//
//  ViewController.swift
//  Loafy
//
//  Created by Dei on 10.02.2020.
//  Copyright © 2020 Solden Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: - Private Types
    
    private typealias RectImagePair = (NSRect, NSImage?)
    
    // MARK: - Private Properties
    
    private let dashPattern: [CGFloat] = [24, 10]
    private let dashWidth: CGFloat = 8
    private let dashColor = NSColor.red
    private let fillColor = NSColor.white
    
    @IBOutlet private weak var previewImageView: NSImageView!
    @IBOutlet private weak var customView: NSView!
    
    private var selectedImageName: String?
    private var rectImagePairs = [RectImagePair]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewImageView.imageScaling = .scaleProportionallyUpOrDown
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        processImageForCurrentSetup(image: nil)
    }
    
    override var representedObject: Any? {
        didSet { }
    }
    
    // MARK: - Private Methods
    
    private func processImageForCurrentSetup(image sourceImage: NSImage?) {
        let translatedScreenRects = getTranslatedScreenRects()
        
        guard let maxX = (translatedScreenRects.max { $0.maxX < $1.maxX })?.maxX,
            let maxY = (translatedScreenRects.max { $0.maxY < $1.maxY })?.maxY else {
                return
        }
        
        let wrappingRectSize = CGSize(width: maxX, height: maxY)
        
        let scaledImage = sourceImage?.resizeToFit(wrappingRectSize)
        
        let rectImagePairs = sliceImagesForRects(scaledImage, rects: translatedScreenRects)
        self.rectImagePairs = rectImagePairs
        
        let previewImage = makePreviewImage(rectImagePairs: rectImagePairs, wrappingRectSize: wrappingRectSize)
        previewImageView.image = previewImage
    }
    
    private func makePreviewImage(rectImagePairs: [RectImagePair], wrappingRectSize: CGSize) -> NSImage? {
        let wrappingRectWithDashGap = CGRect(x: 0,
                                             y: 0,
                                             width: wrappingRectSize.width + dashWidth,
                                             height: wrappingRectSize.height + dashWidth)
        
        let previewImage = NSImage(size: wrappingRectWithDashGap.size)
        previewImage.lockFocus()
        
        fillColor.setFill()
        
        for rectImagePair in rectImagePairs {
            let screen = rectImagePair.0
            
            let dashedScreenRect = CGRect(x: screen.minX + dashWidth / 2,
                                          y: screen.minY + dashWidth / 2,
                                          width: screen.width - dashWidth,
                                          height: screen.height - dashWidth)
            
            dashedScreenRect.fill()
            
            if let image = rectImagePair.1 {
                image.draw(in: dashedScreenRect)
            }
            
            let dashedScreenPath = NSBezierPath(rect: dashedScreenRect)
            dashColor.setStroke()
            dashedScreenPath.lineWidth = dashWidth
            dashedScreenPath.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            dashedScreenPath.stroke()
        }
        
        previewImage.unlockFocus()
        
        return previewImage
    }
    
    private func sliceImagesForRects(_ image: NSImage?, rects: [NSRect]) -> [RectImagePair] {
        var slicedImages = [RectImagePair]()
        
        for rect in rects {
            let trimmedImage = image?.trim(to: rect)
            let rectImagePair = (rect, trimmedImage)
            slicedImages.append(rectImagePair)
        }
        
        return slicedImages
    }
    
    private func getTranslatedScreenRects() -> [NSRect] {
        let screens = NSScreen.screens
        guard let minX = (screens.min { $0.frame.minX < $1.frame.minX })?.frame.minX,
            let minY = (screens.min { $0.frame.minY < $1.frame.minY })?.frame.minY else {
                return []
        }
        
        var translatedScreenRects = [NSRect]()
        
        for screen in screens {
            let translatedScreenRect = CGRect(x: screen.frame.minX - minX,
                                              y: screen.frame.minY - minY,
                                              width: screen.frame.width,
                                              height: screen.frame.height)
            translatedScreenRects.append(translatedScreenRect)
        }
        
        return translatedScreenRects
    }
    
    private func loadImage(at url: URL) {
        guard let selectedImage = NSImage(contentsOf: url) else {
            return
        }
        
        selectedImageName = url.deletingPathExtension().lastPathComponent
        processImageForCurrentSetup(image: selectedImage)
    }
    
    private func saveResultImages(to destinationURL: URL) {
        let images = rectImagePairs.compactMap { $0.1 }
        let imagesCommonName = selectedImageName ?? "Image"
        
        for (index, image) in images.enumerated() {
            let imageName = imagesCommonName + "-\(index + 1).png"
            let imageURL = destinationURL.appendingPathComponent(imageName)
            
            guard let tiffRepresentation = image.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
                    continue
            }
            
            let pngRepresentation = bitmapImage.representation(using: .png, properties: [:])
            
            do {
                try pngRepresentation?.write(to: imageURL)
            }
            catch {
                print(error)
            }
        }
    }
    
    @IBAction private func loadButtonPressed(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.title                   = "Choose an image file"
        openPanel.showsResizeIndicator    = true
        openPanel.showsHiddenFiles        = false
        openPanel.canChooseDirectories    = false
        openPanel.canCreateDirectories    = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes        = ["png", "jpg", "jpeg"]
        
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            guard let imageURL = openPanel.url else {
                return
            }
            
            loadImage(at: imageURL)
        }
    }
    
    @IBAction private func saveButtonPressed(sender: AnyObject) {
        let savePanel = NSOpenPanel()
        savePanel.allowsMultipleSelection = false
        savePanel.canChooseDirectories = true
        savePanel.canCreateDirectories = false
        savePanel.canChooseFiles = false
        savePanel.prompt = "Save here"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        savePanel.begin { [weak self] (result) in
            if result == NSApplication.ModalResponse.OK {
                guard let destinationURL = savePanel.url else {
                    return
                }
                
                self?.saveResultImages(to: destinationURL)
            }
        }
    }
}
