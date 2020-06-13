//
//  ViewController.swift
//  App
//
//  Created by NikolayMakhonin on 2020/06/12
//

class Device {
    var peripheral: CBPeripheral!
    var rssi: NSNumber!
    var updateDate: NSDate!
}

import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var devices: [UUID: Device] = [:]
    private var devicesArray: [Device] = []
    private var devicesArrayDisplay: [Device] = []
    private var devicesArrayLock: Bool = false
    private var lastScannedDate: NSDate = NSDate()
    private var count0: Int = 0
    private var count1: Int = 0
    private var count2: Int = 0
    @IBOutlet weak var labelState: UILabel!
    @IBOutlet weak var labelCount0: UILabel!
    @IBOutlet weak var labelCount1: UILabel!
    @IBOutlet weak var labelCount2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateState)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        labelState.isUserInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.labelState_doubleTap))
        doubleTap.numberOfTapsRequired = 2
        labelState.addGestureRecognizer(doubleTap)
    }
    
    @objc func labelState_doubleTap() {
        devicesArrayLock = !devicesArrayLock
        print("devicesArrayLock = \(devicesArrayLock)")
        updateState(timer: nil)
    }
       
    func updateState(timer: Timer?) {
        devicesArray = Array(devices.values)
        devicesArray.sort(by: {
            if (-$0.updateDate.timeIntervalSinceNow > 10) {
                if (-$1.updateDate.timeIntervalSinceNow > 10) {
                    return -$0.updateDate.timeIntervalSinceNow < -$1.updateDate.timeIntervalSinceNow
                }
                return false
            }
            if (-$1.updateDate.timeIntervalSinceNow > 10) {
                return true
            }
            return Double(truncating: $0.rssi) > Double(truncating: $1.rssi)
        })
        
        if (!devicesArrayLock) {
            devicesArrayDisplay = Array(devicesArray
                .filter({ -$0.updateDate.timeIntervalSinceNow < 60 * 60 })
                .prefix(50))
        }
        
        let devicesStr = devicesArrayDisplay
            .map({ "\($0.rssi ?? 0) | \(Int(-$0.updateDate.timeIntervalSinceNow)) | \($0.peripheral.name ?? "\($0.peripheral.identifier)")"})
            .joined(separator: "\n")
        
        labelState.text = "power\(centralManager.state == .poweredOn ? "On" : "Off") | \(centralManager.isScanning ? "scanning" : "") | \(devicesArray.count) | \(devicesArrayLock ? "lock" : "")\n\(devicesStr)"
        
        let _count0 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 10 }).count
        let _count1 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 60 * 3 }).count
        let _count2 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 60 * 30 }).count
        
        labelCount0.text = "\(_count0)"
        labelCount1.text = "\(_count1)"
        labelCount2.text = "\(_count2)"

        if (count1 < 3 && _count1 > count1) {
            // UINotificationFeedbackGenerator().notificationOccurred(.warning)
            // UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            print("vibrate")
        }

        // print("refresh: \(devicesArray.count)")
        
        count0 = _count0
        count1 = _count1
        count2 = _count2
     
        if (centralManager.state == .poweredOn
            && (!centralManager.isScanning || -lastScannedDate.timeIntervalSinceNow > 10)) {
            lastScannedDate = NSDate()
            // centralManager.stopScan()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    // MARK: bluetooth
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for ...");
            // centralManager.stopScan()
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // print("\(RSSI) | \(peripheral.name ?? "\(peripheral.identifier)")")
        
        var device = devices[peripheral.identifier]
        if (device == nil) {
            device = Device()
            devices[peripheral.identifier] = device
        }
        
        device!.peripheral = peripheral
        device!.rssi = RSSI == 127 ? -128 : RSSI
        device!.updateDate = NSDate()
        
        lastScannedDate = NSDate()
    }
}
