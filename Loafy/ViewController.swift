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
    
    private let dashPattern: [CGFloat] = [24, 10]
    private let dashWidth: CGFloat = 8
    private let dashColor = NSColor.red
    private let fillColor = NSColor.white
    
    @IBOutlet private weak var previewImageView: NSImageView!
    @IBOutlet private weak var customView: NSView!
    
    private var selectedImageName: String?
    private var screenImageModels = [ScreenImageModel]()
    
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
        var models = getTranslatedScreenImageModels()
        
        let translaedRects = models.compactMap { $0.translatedRect }
        
        guard let maxX = (translaedRects.max { $0.maxX < $1.maxX })?.maxX,
            let maxY = (translaedRects.max { $0.maxY < $1.maxY })?.maxY else {
                return
        }
        
        let wrappingRectSize = CGSize(width: maxX, height: maxY)
        
        if let scaledImage = sourceImage?.resizeToFit(wrappingRectSize) {
            for (index, model) in models.enumerated() {
                let translatedRect = model.translatedRect
                let trimmedImage = scaledImage.trim(to: translatedRect)
                let modelWithImage = ScreenImageModel(screen: model.screen,
                                                      translatedRect: model.translatedRect,
                                                      image: trimmedImage)
                models[index] = modelWithImage
            }
        }
        
        self.screenImageModels = models
        
        let previewImage = makePreviewImage(screenImageModels: models, wrappingRectSize: wrappingRectSize)
        previewImageView.image = previewImage
    }
    
    private func makePreviewImage(screenImageModels: [ScreenImageModel], wrappingRectSize: CGSize) -> NSImage? {
        let wrappingRectWithDashGap = CGRect(x: 0,
                                             y: 0,
                                             width: wrappingRectSize.width + dashWidth,
                                             height: wrappingRectSize.height + dashWidth)
        
        let previewImage = NSImage(size: wrappingRectWithDashGap.size)
        previewImage.lockFocus()
        
        fillColor.setFill()
        
        for screenImageModel in screenImageModels {
            let screenFrame = screenImageModel.translatedRect
            
            let dashedScreenRect = CGRect(x: screenFrame.minX + dashWidth / 2,
                                          y: screenFrame.minY + dashWidth / 2,
                                          width: screenFrame.width - dashWidth,
                                          height: screenFrame.height - dashWidth)
            
            dashedScreenRect.fill()
            
            if let image = screenImageModel.image {
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
    
    private func getTranslatedScreenImageModels() -> [ScreenImageModel] {
        let screens = NSScreen.screens
        guard let minX = (screens.min { $0.frame.minX < $1.frame.minX })?.frame.minX,
            let minY = (screens.min { $0.frame.minY < $1.frame.minY })?.frame.minY else {
                return []
        }
        
        var translatedScreenImageModels = [ScreenImageModel]()
        
        for screen in screens {
            let translatedScreenRect = CGRect(x: screen.frame.minX - minX,
                                              y: screen.frame.minY - minY,
                                              width: screen.frame.width,
                                              height: screen.frame.height)
            let model = ScreenImageModel(screen: screen,
                                         translatedRect: translatedScreenRect,
                                         image: nil)
            translatedScreenImageModels.append(model)
        }
        
        return translatedScreenImageModels
    }
    
    private func loadImage(at url: URL) {
        guard let selectedImage = NSImage(contentsOf: url) else {
            return
        }
        
        selectedImageName = url.deletingPathExtension().lastPathComponent
        processImageForCurrentSetup(image: selectedImage)
    }
    
    private func saveResultImages(to destinationURL: URL, shouldSetWallpapers: Bool) {
        let imagesCommonName = selectedImageName ?? "Image"
        let models = self.screenImageModels
        
        for (index, model) in models.enumerated() {
            let screen = model.screen
            let imageName = imagesCommonName + "-\(index + 1).png"
            let imageURL = destinationURL.appendingPathComponent(imageName)
            
            guard let image = model.image,
                let tiffRepresentation = image.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
                    continue
            }
            
            let pngRepresentation = bitmapImage.representation(using: .png, properties: [:])
            
            do {
                try pngRepresentation?.write(to: imageURL)
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: [:])
            }
            catch {
                print(error)
            }
        }
    }
    
    private func saveImagesWithPanelPrompt(shouldSetWallpapers: Bool) {
        let saveButtonPrompt = shouldSetWallpapers
            ? "Save and Set"
            : "Save"
        
        let savePanel = NSOpenPanel()
        savePanel.allowsMultipleSelection = false
        savePanel.canChooseDirectories = true
        savePanel.canCreateDirectories = false
        savePanel.canChooseFiles = false
        savePanel.prompt = saveButtonPrompt
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        savePanel.begin { [weak self] (result) in
            if result == NSApplication.ModalResponse.OK {
                guard let destinationURL = savePanel.url else {
                    return
                }
                
                self?.saveResultImages(to: destinationURL, shouldSetWallpapers: shouldSetWallpapers)
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
    
    @IBAction private func setButtonPressed(sender: AnyObject) {
        saveImagesWithPanelPrompt(shouldSetWallpapers: true)
    }
    
    @IBAction private func saveButtonPressed(sender: AnyObject) {
        saveImagesWithPanelPrompt(shouldSetWallpapers: false)
    }
    
}
