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

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var devices: [UUID: Device] = [:]
    private var lastScannedDate: NSDate = NSDate()
    @IBOutlet weak var labelState: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateState)
    }
    
    func updateState(timer: Timer) {
        var devicesArray = Array(devices.values)
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
        
        let devicesStr = devicesArray
            .filter({ -$0.updateDate.timeIntervalSinceNow < 60 * 60 })
            .map({ "\($0.rssi ?? 0) | \(Int(-$0.updateDate.timeIntervalSinceNow)) | \($0.peripheral.name ?? "\($0.peripheral.identifier)")"})
            .joined(separator: "\n")
        
        labelState.text = "power\(centralManager.state == .poweredOn ? "On" : "Off") \(centralManager.isScanning ? "scanning" : "")\n\(devicesStr)"
        
        if (centralManager.state == .poweredOn
            && (!centralManager.isScanning || -lastScannedDate.timeIntervalSinceNow > 10)) {
            lastScannedDate = NSDate()
            centralManager.stopScan()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for ...");
            centralManager.stopScan()
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
        device!.rssi = RSSI
        device!.updateDate = NSDate()
        
        lastScannedDate = NSDate()
    }
}
