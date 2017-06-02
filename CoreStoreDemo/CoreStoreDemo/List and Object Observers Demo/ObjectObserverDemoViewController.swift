//
//  ObjectObserverDemoViewController.swift
//  CoreStoreDemo
//
//  Created by John Rommel Estropia on 2015/05/06.
//  Copyright © 2015 John Rommel Estropia. All rights reserved.
//

import UIKit
import CoreStore


// MARK: - ObjectObserverDemoViewController

class ObjectObserverDemoViewController: UIViewController, ObjectObserver {
    
    var palette: Palette? {
        
        get {
            
            return self.monitor?.object
        }
        set {
            
            guard self.monitor?.object != newValue else {
                
                return
            }
            
            if let palette = newValue {
                
                self.monitor = CoreStore.monitorObject(palette)
            }
            else {
                
                self.monitor = nil
            }
        }
    }
    
    // MARK: NSObject
    
    deinit {
        
        self.monitor?.removeObserver(self)
    }
    

    // MARK: UIViewController
    
    required init?(coder aDecoder: NSCoder) {
        
        if let palette = CoreStore.fetchOne(From<Palette>(), OrderBy(.ascending(#keyPath(Palette.hue)))) {
            
            self.monitor = CoreStore.monitorObject(palette)
        }
        else {
            
            CoreStore.beginSynchronous { (transaction) -> Void in
                
                let palette = transaction.create(Into(Palette.self))
                palette.setInitialValues()
                
                _ = transaction.commitAndWait()
            }
            
            let palette = CoreStore.fetchOne(From<Palette>(), OrderBy(.ascending(#keyPath(Palette.hue))))!
            self.monitor = CoreStore.monitorObject(palette)
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.monitor?.addObserver(self)
        
        if let palette = self.monitor?.object {
            
            self.reloadPaletteInfo(palette, changedKeys: nil)
        }
    }
    
    
    // MARK: ObjectObserver
    
    func objectMonitor(_ monitor: ObjectMonitor<Palette>, didUpdateObject object: Palette, changedPersistentKeys: Set<KeyPath>) {
        
        self.reloadPaletteInfo(object, changedKeys: changedPersistentKeys)
    }
    
    func objectMonitor(_ monitor: ObjectMonitor<Palette>, didDeleteObject object: Palette) {
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.colorNameLabel?.alpha = 0.3
        self.colorView?.alpha = 0.3
        
        self.hsbLabel?.text = "Deleted"
        self.hsbLabel?.textColor = UIColor.red
        
        self.hueSlider?.isEnabled = false
        self.saturationSlider?.isEnabled = false
        self.brightnessSlider?.isEnabled = false
    }

    
    // MARK: Private
    
    var monitor: ObjectMonitor<Palette>?
    
    @IBOutlet weak var colorNameLabel: UILabel?
    @IBOutlet weak var colorView: UIView?
    @IBOutlet weak var hsbLabel: UILabel?
    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var hueSlider: UISlider?
    @IBOutlet weak var saturationSlider: UISlider?
    @IBOutlet weak var brightnessSlider: UISlider?
    
    @IBAction dynamic func hueSliderValueDidChange(_ sender: AnyObject?) {
        
        let hue = self.hueSlider?.value ?? 0
        CoreStore.beginAsynchronous { [weak self] (transaction) -> Void in
            
            if let palette = transaction.edit(self?.monitor?.object) {
                
                palette.hue = Int32(hue)
                transaction.commit()
            }
        }
    }
    
    @IBAction dynamic func saturationSliderValueDidChange(_ sender: AnyObject?) {
        
        let saturation = self.saturationSlider?.value ?? 0
        CoreStore.beginAsynchronous { [weak self] (transaction) -> Void in
            
            if let palette = transaction.edit(self?.monitor?.object) {
                
                palette.saturation = saturation
                transaction.commit()
            }
        }
    }
    
    @IBAction dynamic func brightnessSliderValueDidChange(_ sender: AnyObject?) {
        
        let brightness = self.brightnessSlider?.value ?? 0
        CoreStore.beginAsynchronous { [weak self] (transaction) -> Void in
            
            if let palette = transaction.edit(self?.monitor?.object) {
                
                palette.brightness = brightness
                transaction.commit()
            }
        }
    }
    
    @IBAction dynamic func deleteBarButtonTapped(_ sender: AnyObject?) {
        
        CoreStore.beginAsynchronous { [weak self] (transaction) -> Void in
            
            transaction.delete(self?.monitor?.object)
            transaction.commit()
        }
    }
    
    func reloadPaletteInfo(_ palette: Palette, changedKeys: Set<String>?) {
        
        self.colorNameLabel?.text = palette.colorName
        
        let color = palette.color
        self.colorNameLabel?.textColor = color
        self.colorView?.backgroundColor = color
        
        self.hsbLabel?.text = palette.colorText
        
        if changedKeys == nil || changedKeys?.contains(#keyPath(Palette.hue)) == true {
            
            self.hueSlider?.value = Float(palette.hue)
        }
        if changedKeys == nil || changedKeys?.contains(#keyPath(Palette.saturation)) == true {
            
            self.saturationSlider?.value = palette.saturation
        }
        if changedKeys == nil || changedKeys?.contains(#keyPath(Palette.brightness)) == true {
            
            self.brightnessSlider?.value = palette.brightness
        }
    }
}
